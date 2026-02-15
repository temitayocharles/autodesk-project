package main

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	amqp "github.com/rabbitmq/amqp091-go"
	log "github.com/sirupsen/logrus"
)

// Config holds application configuration
type Config struct {
	RabbitMQURL      string
	QueueName        string
	WorkerCount      int
	MetricsPort      string
	HealthCheckPort  string
	DisableRabbitMQ  bool
}

// FileProcessingMessage represents a file to be processed
type FileProcessingMessage struct {
	FileID      int       `json:"file_id"`
	Filename    string    `json:"filename"`
	S3Key       string    `json:"s3_key"`
	S3Bucket    string    `json:"s3_bucket"`
	ProjectID   string    `json:"project_id"`
	ProcessType string    `json:"process_type"`
	Timestamp   time.Time `json:"timestamp"`
}

// Prometheus metrics
var (
	messagesProcessed = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "messages_processed_total",
			Help: "Total number of messages processed",
		},
		[]string{"status"},
	)
	processingDuration = prometheus.NewHistogram(
		prometheus.HistogramOpts{
			Name:    "message_processing_duration_seconds",
			Help:    "Time spent processing messages",
			Buckets: prometheus.DefBuckets,
		},
	)
)

func init() {
	// Configure structured logging
	log.SetFormatter(&log.JSONFormatter{})
	log.SetOutput(os.Stdout)
	log.SetLevel(log.InfoLevel)

	// Register Prometheus metrics
	prometheus.MustRegister(messagesProcessed)
	prometheus.MustRegister(processingDuration)
}

func main() {
	log.Info("Starting Data Processing Service")

	// Load configuration
	config := loadConfig()

	// Connect to RabbitMQ
	var msgs <-chan amqp.Delivery
	var conn *amqp.Connection
	var ch *amqp.Channel
	if config.DisableRabbitMQ {
		log.Warn("RABBITMQ disabled; running health/metrics only")
	} else {
		var err error
		conn, err = connectRabbitMQ(config.RabbitMQURL)
		if err != nil {
			log.Fatalf("Failed to connect to RabbitMQ: %v", err)
		}
		defer conn.Close()

		ch, err = conn.Channel()
		if err != nil {
			log.Fatalf("Failed to create channel: %v", err)
		}
		defer ch.Close()

		q, err := ch.QueueDeclare(
			config.QueueName, // name
			true,             // durable
			false,            // delete when unused
			false,            // exclusive
			false,            // no-wait
			nil,              // arguments
		)
		if err != nil {
			log.Fatalf("Failed to declare queue: %v", err)
		}

		err = ch.Qos(
			1,     // prefetch count
			0,     // prefetch size
			false, // global
		)
		if err != nil {
			log.Fatalf("Failed to set QoS: %v", err)
		}

		msgs, err = ch.Consume(
			q.Name, // queue
			"",     // consumer
			false,  // auto-ack
			false,  // exclusive
			false,  // no-local
			false,  // no-wait
			nil,    // args
		)
		if err != nil {
			log.Fatalf("Failed to register consumer: %v", err)
		}
	}

	// Start metrics server
	go startMetricsServer(config.MetricsPort)

	// Start health check server
	go startHealthCheckServer(config.HealthCheckPort)

	// Create context for graceful shutdown
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	if config.DisableRabbitMQ {
		log.Info("RabbitMQ disabled: not starting workers")
	} else {
		for i := 0; i < config.WorkerCount; i++ {
			go worker(ctx, i, msgs)
		}
		log.Infof("Started %d workers, waiting for messages...", config.WorkerCount)
	}

	// Wait for interrupt signal
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)
	<-sigChan

	log.Info("Received shutdown signal, gracefully shutting down...")
	cancel()
	time.Sleep(2 * time.Second) // Give workers time to finish
	log.Info("Shutdown complete")
}

func loadConfig() *Config {
	return &Config{
		RabbitMQURL:     getEnv("RABBITMQ_URL", "amqp://guest:guest@localhost:5672/"),
		QueueName:       getEnv("QUEUE_NAME", "aec-data-processing"),
		WorkerCount:     5,
		MetricsPort:     getEnv("METRICS_PORT", "9091"),
		HealthCheckPort: getEnv("HEALTH_PORT", "8081"),
		DisableRabbitMQ: getEnv("DISABLE_RABBITMQ", "0") == "1",
	}
}

func getEnv(key, defaultValue string) string {
	value := os.Getenv(key)
	if value == "" {
		return defaultValue
	}
	return value
}

func connectRabbitMQ(url string) (*amqp.Connection, error) {
	maxRetries := 5
	retryDelay := 5 * time.Second

	for i := 0; i < maxRetries; i++ {
		conn, err := amqp.Dial(url)
		if err == nil {
			log.Info("Successfully connected to RabbitMQ")
			return conn, nil
		}

		log.Warnf("Failed to connect to RabbitMQ (attempt %d/%d): %v", i+1, maxRetries, err)
		if i < maxRetries-1 {
			time.Sleep(retryDelay)
		}
	}

	return nil, fmt.Errorf("failed to connect to RabbitMQ after %d attempts", maxRetries)
}

func worker(ctx context.Context, id int, msgs <-chan amqp.Delivery) {
	log.Infof("Worker %d started", id)

	for {
		select {
		case <-ctx.Done():
			log.Infof("Worker %d stopping", id)
			return
		case msg, ok := <-msgs:
			if !ok {
				log.Infof("Worker %d: channel closed", id)
				return
			}

			// Process message
			timer := prometheus.NewTimer(processingDuration)
			err := processMessage(msg.Body)
			timer.ObserveDuration()

			if err != nil {
				log.Errorf("Worker %d: Error processing message: %v", id, err)
				msg.Nack(false, true) // Requeue on error
				messagesProcessed.WithLabelValues("error").Inc()
			} else {
				log.Infof("Worker %d: Message processed successfully", id)
				msg.Ack(false)
				messagesProcessed.WithLabelValues("success").Inc()
			}
		}
	}
}

func processMessage(body []byte) error {
	var msg FileProcessingMessage
	err := json.Unmarshal(body, &msg)
	if err != nil {
		return fmt.Errorf("failed to unmarshal message: %w", err)
	}

	log.WithFields(log.Fields{
		"file_id":      msg.FileID,
		"filename":     msg.Filename,
		"project_id":   msg.ProjectID,
		"process_type": msg.ProcessType,
	}).Info("Processing file")

	// Simulate data processing
	// In a real application, this would:
	// 1. Download file from S3
	// 2. Process/transform data
	// 3. Store results
	// 4. Publish completion event

	switch msg.ProcessType {
	case "validate":
		return validateFile(&msg)
	case "transform":
		return transformFile(&msg)
	case "analyze":
		return analyzeFile(&msg)
	default:
		return fmt.Errorf("unknown process type: %s", msg.ProcessType)
	}
}

func validateFile(msg *FileProcessingMessage) error {
	log.Infof("Validating file: %s", msg.Filename)
	// Simulate validation work
	time.Sleep(100 * time.Millisecond)
	return nil
}

func transformFile(msg *FileProcessingMessage) error {
	log.Infof("Transforming file: %s", msg.Filename)
	// Simulate transformation work
	time.Sleep(500 * time.Millisecond)
	return nil
}

func analyzeFile(msg *FileProcessingMessage) error {
	log.Infof("Analyzing file: %s", msg.Filename)
	// Simulate analysis work
	time.Sleep(300 * time.Millisecond)
	return nil
}

func startMetricsServer(port string) {
	http.Handle("/metrics", promhttp.Handler())
	addr := fmt.Sprintf(":%s", port)
	log.Infof("Starting metrics server on %s", addr)
	if err := http.ListenAndServe(addr, nil); err != nil {
		log.Fatalf("Failed to start metrics server: %v", err)
	}
}

func startHealthCheckServer(port string) {
	mux := http.NewServeMux()

	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status":    "healthy",
			"service":   "data-processing-service",
			"timestamp": time.Now().UTC(),
		})
	})

	mux.HandleFunc("/ready", func(w http.ResponseWriter, r *http.Request) {
		// Check RabbitMQ connectivity
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status": "ready",
		})
	})

	addr := fmt.Sprintf(":%s", port)
	log.Infof("Starting health check server on %s", addr)
	if err := http.ListenAndServe(addr, mux); err != nil {
		log.Fatalf("Failed to start health check server: %v", err)
	}
}
