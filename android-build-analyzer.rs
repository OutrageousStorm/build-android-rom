//! Android ROM Build Analyzer - Rust Tool
//! Analyzes AOSP/LineageOS build dependencies and optimization opportunities

use std::collections::{HashMap, HashSet};
use std::fs;
use std::path::Path;

#[derive(Debug, Clone)]
pub struct BuildDependency {
    name: String,
    module_type: String,
    build_time_est: u32, // seconds
    size: u64,           // bytes
}

#[derive(Debug)]
pub struct BuildAnalysis {
    total_modules: usize,
    total_build_time: u32,
    total_size: u64,
    slow_modules: Vec<BuildDependency>,
    large_modules: Vec<BuildDependency>,
    unused_modules: Vec<String>,
}

pub struct AndroidBuildAnalyzer {
    dependencies: Vec<BuildDependency>,
    module_map: HashMap<String, BuildDependency>,
}

impl AndroidBuildAnalyzer {
    pub fn new() -> Self {
        AndroidBuildAnalyzer {
            dependencies: Vec::new(),
            module_map: HashMap::new(),
        }
    }

    /// Load modules from Android.mk or Android.bp files
    pub fn load_modules_from_file(&mut self, path: &str) -> Result<usize, String> {
        let content = fs::read_to_string(path)
            .map_err(|e| format!("Failed to read file {}: {}", path, e))?;

        let mut count = 0;

        for line in content.lines() {
            if line.contains("LOCAL_MODULE :=") {
                if let Some(module_name) = line.split(":=").nth(1) {
                    let dep = BuildDependency {
                        name: module_name.trim().to_string(),
                        module_type: Self::detect_module_type(&content),
                        build_time_est: Self::estimate_build_time(&content),
                        size: Self::estimate_module_size(&content),
                    };

                    self.module_map
                        .insert(dep.name.clone(), dep.clone());
                    self.dependencies.push(dep);
                    count += 1;
                }
            }
        }

        Ok(count)
    }

    /// Detect module type (library, executable, app, etc.)
    fn detect_module_type(content: &str) -> String {
        if content.contains("LOCAL_MODULE_CLASS := JAVA_LIBRARIES") {
            "Java Library".to_string()
        } else if content.contains("LOCAL_MODULE_CLASS := EXECUTABLES") {
            "Executable".to_string()
        } else if content.contains("LOCAL_PACKAGE_NAME :=") {
            "System App".to_string()
        } else if content.contains("cc_library") {
            "Native Library".to_string()
        } else {
            "Unknown".to_string()
        }
    }

    /// Estimate build time based on complexity
    fn estimate_build_time(content: &str) -> u32 {
        let mut time = 10; // base time

        // Increase for language complexity
        if content.contains(".java") {
            time += 5;
        }
        if content.contains(".cc") || content.contains(".cpp") {
            time += 10;
        }
        if content.contains("PROTOC") {
            time += 3;
        }
        if content.contains("AIDL") {
            time += 2;
        }

        time
    }

    /// Estimate module size based on file references
    fn estimate_module_size(content: &str) -> u64 {
        let file_count = content.matches("LOCAL_SRC_FILES").count() as u64;
        file_count * 50_000 // rough estimate: 50KB per source file
    }

    /// Analyze build for optimization opportunities
    pub fn analyze(&self) -> BuildAnalysis {
        let mut slow_modules: Vec<_> = self.dependencies.clone();
        slow_modules.sort_by(|a, b| b.build_time_est.cmp(&a.build_time_est));
        slow_modules.truncate(10);

        let mut large_modules: Vec<_> = self.dependencies.clone();
        large_modules.sort_by(|a, b| b.size.cmp(&a.size));
        large_modules.truncate(10);

        let total_build_time: u32 = self.dependencies.iter().map(|d| d.build_time_est).sum();
        let total_size: u64 = self.dependencies.iter().map(|d| d.size).sum();

        BuildAnalysis {
            total_modules: self.dependencies.len(),
            total_build_time,
            total_size,
            slow_modules,
            large_modules,
            unused_modules: Vec::new(),
        }
    }

    /// Generate optimization recommendations
    pub fn get_recommendations(&self) -> Vec<String> {
        let mut recommendations = Vec::new();

        if self.dependencies.len() > 500 {
            recommendations.push(
                "High module count (>500). Consider breaking build into smaller components"
                    .to_string(),
            );
        }

        let java_modules = self
            .dependencies
            .iter()
            .filter(|d| d.module_type == "Java Library")
            .count();
        if java_modules > 200 {
            recommendations.push("Large number of Java libraries. Enable parallel Java compilation"
                .to_string());
        }

        let analysis = self.analyze();
        if analysis.total_build_time > 3600 {
            recommendations.push(
                "Build time >1hr. Consider: ninja jobs, ccache, or incremental builds"
                    .to_string(),
            );
        }

        recommendations
    }

    /// Print detailed analysis report
    pub fn print_report(&self) {
        let analysis = self.analyze();

        println!("\n╔═══════════════════════════════════════════╗");
        println!("║  ANDROID BUILD DEPENDENCY ANALYSIS        ║");
        println!("╚═══════════════════════════════════════════╝\n");

        println!("📊 Build Summary:");
        println!("   Total Modules: {}", analysis.total_modules);
        println!(
            "   Est. Build Time: {}m {}s",
            analysis.total_build_time / 60,
            analysis.total_build_time % 60
        );
        println!(
            "   Total Size: {:.2} GB",
            analysis.total_size as f64 / 1_000_000_000.0
        );

        println!("\n⏱️  Top 10 Slowest Modules:");
        for (i, module) in analysis.slow_modules.iter().enumerate() {
            println!(
                "   {}. {} ({}) - {}s",
                i + 1,
                module.name,
                module.module_type,
                module.build_time_est
            );
        }

        println!("\n📦 Top 10 Largest Modules:");
        for (i, module) in analysis.large_modules.iter().enumerate() {
            println!(
                "   {}. {} - {:.1} MB",
                i + 1,
                module.name,
                module.size as f64 / 1_000_000.0
            );
        }

        println!("\n💡 Optimization Recommendations:");
        for (i, rec) in self.get_recommendations().iter().enumerate() {
            println!("   {}. {}", i + 1, rec);
        }

        println!();
    }
}

fn main() {
    let args: Vec<String> = std::env::args().collect();

    if args.len() < 2 {
        eprintln!("Usage: android-build-analyzer <Android.mk or Android.bp file>");
        std::process::exit(1);
    }

    let mut analyzer = AndroidBuildAnalyzer::new();

    match analyzer.load_modules_from_file(&args[1]) {
        Ok(count) => {
            println!("✓ Loaded {} modules from {}", count, args[1]);
            analyzer.print_report();
        }
        Err(e) => {
            eprintln!("✗ Error: {}", e);
            std::process::exit(1);
        }
    }
}
