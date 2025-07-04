use std::time::{Duration, Instant};
use tokio::time::timeout;
use anyhow::Result;

// Performance test configuration
const BENCHMARK_ITERATIONS: usize = 100;

// Performance metrics structure
#[derive(Debug, Clone)]
struct PerformanceMetrics {
    total_requests: usize,
    successful_requests: usize,
    failed_requests: usize,
    total_duration: Duration,
    average_response_time: Duration,
    requests_per_second: f64,
}

impl PerformanceMetrics {
    fn new() -> Self {
        Self {
            total_requests: 0,
            successful_requests: 0,
            failed_requests: 0,
            total_duration: Duration::ZERO,
            average_response_time: Duration::ZERO,
            requests_per_second: 0.0,
        }
    }

    fn add_request(&mut self, duration: Duration, success: bool) {
        self.total_requests += 1;
        if success {
            self.successful_requests += 1;
        } else {
            self.failed_requests += 1;
        }

        self.total_duration += duration;
        self.average_response_time = self.total_duration / self.total_requests as u32;
        self.requests_per_second = self.total_requests as f64 / self.total_duration.as_secs_f64();
    }

    fn print_summary(&self) {
        println!("📊 Performance Test Results:");
        println!("   Total Requests: {}", self.total_requests);
        println!("   Successful: {}", self.successful_requests);
        println!("   Failed: {}", self.failed_requests);
        println!("   Success Rate: {:.2}%", 
            (self.successful_requests as f64 / self.total_requests as f64) * 100.0);
        println!("   Average Response Time: {:?}", self.average_response_time);
        println!("   Requests/Second: {:.2}", self.requests_per_second);
    }

    fn success_rate(&self) -> f64 {
        if self.total_requests == 0 {
            0.0
        } else {
            self.successful_requests as f64 / self.total_requests as f64
        }
    }
}

// Simulate trade event processing
async fn simulate_trade_processing(trade_id: usize) -> Result<Duration> {
    let start = Instant::now();
    
    // Simulate JSON parsing
    let trade_event = serde_json::json!({
        "user_id": format!("user_{}", trade_id),
        "trade_id": format!("trade_{}", trade_id),
        "pnl": 150.50 + (trade_id as f64 * 0.1),
        "timestamp": "2025-01-01T12:00:00Z",
        "transaction_hash": format!("0x{:016x}", trade_id)
    });
    
    // Simulate processing time
    tokio::time::sleep(Duration::from_millis(10)).await;
    
    // Validate trade event
    let pnl = trade_event["pnl"].as_f64().unwrap();
    if pnl <= 0.0 {
        return Err(anyhow::anyhow!("Invalid PnL"));
    }
    
    // Simulate NFT minting decision
    let should_mint = pnl > 0.0;
    if !should_mint {
        return Err(anyhow::anyhow!("Trade not profitable for NFT minting"));
    }
    
    let duration = start.elapsed();
    Ok(duration)
}

// Benchmark test for single trade processing
#[tokio::test]
async fn test_trade_processing_benchmark() {
    println!("🚀 Starting trade processing benchmark...");
    
    let mut metrics = PerformanceMetrics::new();
    
    for i in 0..BENCHMARK_ITERATIONS {
        let result = simulate_trade_processing(i).await;
        let duration = match result {
            Ok(duration) => {
                metrics.add_request(duration, true);
                duration
            }
            Err(_) => {
                metrics.add_request(Duration::ZERO, false);
                Duration::ZERO
            }
        };
        
        if i % 20 == 0 {
            println!("   Processed {} trades...", i);
        }
    }
    
    metrics.print_summary();
    
    // Performance assertions
    assert!(metrics.success_rate() > 0.95, "Success rate should be > 95%");
    assert!(metrics.average_response_time < Duration::from_millis(100), 
        "Average response time should be < 100ms");
    assert!(metrics.requests_per_second > 5.0, 
        "Should process > 5 requests/second");
    
    println!("✅ Trade processing benchmark completed");
}

// Load test with concurrent requests
#[tokio::test]
async fn test_concurrent_load() {
    println!("🚀 Starting concurrent load test...");
    
    let start = Instant::now();
    let mut handles = Vec::new();
    
    // Spawn concurrent tasks
    for i in 0..50 {
        let handle = tokio::spawn(async move {
            simulate_trade_processing(i).await
        });
        handles.push(handle);
    }
    
    // Wait for all tasks to complete
    let mut metrics = PerformanceMetrics::new();
    for handle in handles {
        match handle.await {
            Ok(Ok(duration)) => {
                metrics.add_request(duration, true);
            }
            Ok(Err(_)) => {
                metrics.add_request(Duration::ZERO, false);
            }
            Err(_) => {
                metrics.add_request(Duration::ZERO, false);
            }
        }
    }
    
    let total_duration = start.elapsed();
    println!("   Total test duration: {:?}", total_duration);
    
    metrics.print_summary();
    
    // Load test assertions
    assert!(metrics.successful_requests > 40, 
        "Should handle concurrent load with > 80% success rate");
    assert!(total_duration < Duration::from_secs(10), 
        "Concurrent load test should complete within 10 seconds");
    
    println!("✅ Concurrent load test completed");
}

// Performance test suite runner
pub async fn run_performance_tests() -> Result<()> {
    println!("🚀 Starting performance test suite...");
    
    // Run all performance tests
    test_trade_processing_benchmark().await;
    test_concurrent_load().await;
    
    println!("🎉 All performance tests completed!");
    Ok(())
} 