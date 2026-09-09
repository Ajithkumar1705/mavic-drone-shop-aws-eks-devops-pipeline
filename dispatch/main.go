package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	amqp "github.com/rabbitmq/amqp091-go"
)

// Prometheus — dispatch has no HTTP server otherwise, so one is added
// purely to serve /metrics. promauto registers this counter with the
// default global registry automatically.
var ordersProcessed = promauto.NewCounter(prometheus.CounterOpts{
	Name: "orders_processed",
	Help: "running count of orders processed by dispatch",
})

var (
	amqpUri          string
	rabbitChan       *amqp.Channel
	rabbitCloseError chan *amqp.Error
	rabbitReady      chan bool
)

func connectToRabbitMQ(uri string) *amqp.Connection {
	for {
		conn, err := amqp.Dial(uri)
		if err == nil {
			return conn
		}

		log.Println(err)
		log.Printf("Reconnecting to %s\n", uri)
		time.Sleep(1 * time.Second)
	}
}

func rabbitConnector(uri string) {
	var rabbitErr *amqp.Error

	for {
		rabbitErr = <-rabbitCloseError
		if rabbitErr == nil {
			return
		}

		log.Printf("Connecting to %s\n", amqpUri)
		rabbitConn := connectToRabbitMQ(uri)
		rabbitConn.NotifyClose(rabbitCloseError)

		var err error

		// create mappings here
		rabbitChan, err = rabbitConn.Channel()
		failOnError(err, "Failed to create channel")

		// create exchange
		err = rabbitChan.ExchangeDeclare("mavic-drone-shop", "direct", true, false, false, false, nil)
		failOnError(err, "Failed to create exchange")

		// create queue
		queue, err := rabbitChan.QueueDeclare("orders", true, false, false, false, nil)
		failOnError(err, "Failed to create queue")

		// bind queue to exchange
		err = rabbitChan.QueueBind(queue.Name, "orders", "mavic-drone-shop", false, nil)
		failOnError(err, "Failed to bind queue")

		// signal ready
		rabbitReady <- true
	}
}

func failOnError(err error, msg string) {
	if err != nil {
		log.Fatalf("%s : %s", msg, err)
	}
}

func main() {
	// Init amqpUri
	// get host from environment
	amqpHost, ok := os.LookupEnv("AMQP_HOST")
	if !ok {
		amqpHost = "rabbitmq"
	}
	amqpUri = fmt.Sprintf("amqp://guest:guest@%s:5672/", amqpHost)

	// MQ error channel
	rabbitCloseError = make(chan *amqp.Error)

	// MQ ready channel
	rabbitReady = make(chan bool)

	go rabbitConnector(amqpUri)

	rabbitCloseError <- amqp.ErrClosed

	go func() {
		for {
			// wait for rabbit to be ready
			ready := <-rabbitReady
			log.Printf("Rabbit MQ ready %v\n", ready)

			// subscribe to bound queue
			msgs, err := rabbitChan.Consume("orders", "", true, false, false, false, nil)
			failOnError(err, "Failed to consume")

			for d := range msgs {
				log.Printf("Order %s\n", d.Body)
				log.Printf("Headers %v\n", d.Headers)
				ordersProcessed.Inc()
			}
		}
	}()

	// Prometheus metrics server — separate from the app's actual work,
	// runs on its own port since dispatch otherwise never listens on
	// anything (it's a pure background worker).
	go func() {
		http.Handle("/metrics", promhttp.Handler())
		log.Println("Serving /metrics on :2112")
		log.Println(http.ListenAndServe(":2112", nil))
	}()

	log.Println("Waiting for messages")
	select {}
}
