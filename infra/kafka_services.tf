# Kafka service
resource "aiven_kafka" "tms-demo-kafka" {
  project = var.avn_project_id
  cloud_name = var.cloud_name
  plan = "startup-2"
  service_name = "tms-demo-kafka"
  maintenance_window_dow = "monday"
  maintenance_window_time = "10:00:00"

  kafka_user_config {
    // Enables Kafka Schemas
    schema_registry = true
    kafka_version = "2.6"
    kafka {
      group_max_session_timeout_ms = 70000
      log_retention_bytes = 1000000000
    }
  }
}

resource "aiven_service_user" "tms-ingest-user" {
  project = var.avn_project_id
  service_name = aiven_kafka.tms-demo-kafka.service_name
  
  username = "tms-ingest-user"

  depends_on = [
    aiven_kafka.tms-demo-kafka
  ]
}

resource "aiven_service_user" "tms-processing-user" {
  project = var.avn_project_id
  service_name = aiven_kafka.tms-demo-kafka.service_name
  
  username = "tms-processing-user"

  depends_on = [
    aiven_kafka.tms-demo-kafka
  ]
}

resource "aiven_service_user" "tms-sink-user" {
  project = var.avn_project_id
  service_name = aiven_kafka.tms-demo-kafka.service_name
  
  username = "tms-sink-user"

  depends_on = [
    aiven_kafka.tms-demo-kafka
  ]
}

// Kafka connect service
resource "aiven_kafka_connect" "tms-demo-kafka-connect1" {
  project = var.avn_project_id
  cloud_name = var.cloud_name
  plan = "startup-4"
  service_name = "tms-demo-kafka-connect1"
  maintenance_window_dow = "monday"
  maintenance_window_time = "10:00:00"

  kafka_connect_user_config {
    kafka_connect {
      consumer_isolation_level = "read_committed"
    }

    public_access {
      kafka_connect = true
    }
  }
}

resource "aiven_kafka_acl" "tms-ingest-acl" {
  project = var.avn_project_id
  service_name = aiven_kafka.tms-demo-kafka.service_name
  permission = "write"
  username = aiven_service_user.tms-ingest-user.username
  topic = aiven_kafka_topic.observations-weather-raw.topic_name
  depends_on = [
    aiven_kafka.tms-demo-kafka
  ]
}

resource "aiven_kafka_acl" "tms-processing-acl" {
  project = var.avn_project_id
  service_name = aiven_kafka.tms-demo-kafka.service_name
  permission = "readwrite"
  username = aiven_service_user.tms-processing-user.username
  topic = "*"
  depends_on = [
    aiven_kafka.tms-demo-kafka
  ]
}

resource "aiven_kafka_acl" "tms-sink-acl" {
  project = var.avn_project_id
  service_name = aiven_kafka.tms-demo-kafka.service_name
  permission = "read"
  username = aiven_service_user.tms-sink-user.username
  topic = aiven_kafka_topic.observations-weather-municipality.topic_name
  depends_on = [
    aiven_kafka.tms-demo-kafka
  ]
}

// Kafka connect service integration
resource "aiven_service_integration" "tms-demo-connect-integr" {
  project = var.avn_project_id
  integration_type = "kafka_connect"
  source_service_name = aiven_kafka.tms-demo-kafka.service_name
  destination_service_name = aiven_kafka_connect.tms-demo-kafka-connect1.service_name

  kafka_connect_user_config {
    kafka_connect {
      group_id = "connect_1"
      status_storage_topic = "__connect_1_status"
      offset_storage_topic = "__connect_1_offsets"
      config_storage_topic = "__connect_1_configs"
    }
  }
}

data "aiven_service_user" "kafka_admin" {
  project = var.avn_project_id
  service_name = aiven_kafka.tms-demo-kafka.service_name

  # default admin user that is automatically created each Aiven service
  username = "avnadmin"

  depends_on = [
    aiven_kafka.tms-demo-kafka
  ]
}
