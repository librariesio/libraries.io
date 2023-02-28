# Update Maven Repository Sources

Add new repository to:

* libraries
    * app/models/package_manager/maven/, duplicate `maven_central.rb` and rework.
    * app/models/package_manager/maven.rb, `PROVIDER_MAP`, add above class.
    * app/workers/package_manager_workload_worker.rb, `PLATFORMS`, add above class.
* depper
    * ingestors/maven.go
      * add constant next to `MavenCentral`
      * add to `GetParser()`
    * main.go, add constant to `registerIngestors`
* maven-updater
  * src/m/j/i/l/m/services/, duplicate `MavenCentralUpdater.javaa and rework.
    * The code uses reflection to find the new updater so you don't need to
      change anything else.
