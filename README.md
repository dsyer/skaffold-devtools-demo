# Devtools in Kubernetes

## Preparation

Get `kind` running locally and a local registry on port 5000, e.g. using the utility script in this repo:

```
src/build/kind-setup.sh
```

Now build the base image (just webflux, no frills):

```
./mvnw spring-boot:build-image
```

Then if you build from the `Dockerfile` it will enhance the image with additional libraries (adds actuators and devtools):

```
docker build . -t demo
```

Run it:

```
docker run -e EXT_LIBS=/workspace/dev -p 8080:8080 demo
```

You will see the devtools starting (via logs and the `restartedMain` thread ID, and there should be actuators

```
$ curl localhost:8080/actuator/info
{"name": "foo"}
```

## Skaffold

To take advantage of the devtools restarts we can deploy to Kubernetes, and let Skaffold sync the file changes:

```
skaffold dev --port-forward -p dev
```

Output:

```
Listing files to watch...
 - localhost:5000/apps/demo
Generating tags...
 - localhost:5000/apps/demo -> localhost:5000/apps/demo:b906cca-dirty
Checking cache...
 - localhost:5000/apps/demo: Found Locally
...
Watching for changes...
[demo] 
[demo]   .   ____          _            __ _ _
[demo]  /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
[demo] ( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
[demo]  \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
[demo]   '  |____| .__|_| |_|_| |_\__, | / / / /
[demo]  =========|_|==============|___/=/_/_/_/
[demo]  :: Spring Boot ::            (v2.3.0.RC1)
[demo] 
[demo] 2020-10-16 10:18:57.498  INFO 9 --- [  restartedMain] com.example.demo.DemoApplication         : Starting DemoApplication on demo-c8d6f9f7d-ljlpq with PID 9 (/workspace/BOOT-INF/classes started by cnb in /workspace)
...
[demo] 2020-10-16 10:18:58.752  INFO 9 --- [  restartedMain] com.example.demo.DemoApplication         : Started DemoApplication in 1.515 seconds (JVM running for 1.863)
Syncing 3 files for localhost:5000/apps/demo:c2a4a6b772d73849eb0cf37bfa0d5c14f85a883c9643e1af7cb8f037a66d22a4
Watching for changes...
```

If you make a change to the application, e.g. tweak the `@GetMapping` on the home page, you will see Skaffold copy the change over and Spring Boot will restart the app.

```
...
[demo] 2020-10-16 10:21:07.217  INFO 9 --- [  restartedMain] o.s.b.web.embedded.netty.NettyWebServer  : Netty started on port(s): 8080
[demo] 2020-10-16 10:21:07.218  INFO 9 --- [  restartedMain] com.example.demo.DemoApplication         : Started DemoApplication in 0.181 seconds (JVM running for 130.329)
[demo] 2020-10-16 10:21:07.220  INFO 9 --- [  restartedMain] .ConditionEvaluationDeltaLoggingListener : Condition evaluation unchanged
Syncing 3 files for localhost:5000/apps/demo:c2a4a6b772d73849eb0cf37bfa0d5c14f85a883c9643e1af7cb8f037a66d22a4
Watching for changes...
[demo] 
[demo]   .   ____          _            __ _ _
[demo]  /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
[demo] ( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
[demo]  \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
[demo]   '  |____| .__|_| |_|_| |_\__, | / / / /
[demo]  =========|_|==============|___/=/_/_/_/
[demo]  :: Spring Boot ::            (v2.3.0.RC1)
[demo] 
[demo] 2020-10-16 10:21:23.806  INFO 9 --- [  restartedMain] com.example.demo.DemoApplication         : Starting DemoApplication on demo-c8d6f9f7d-ljlpq with PID 9 (/workspace/BOOT-INF/classes started by cnb in /workspace)
[demo] 2020-10-16 10:21:23.806  INFO 9 --- [  restartedMain] com.example.demo.DemoApplication         : No active profile set, falling back to default profiles: default
[demo] 2020-10-16 10:21:23.940  INFO 9 --- [  restartedMain] o.s.b.a.e.web.EndpointLinksResolver      : Exposing 4 endpoint(s) beneath base path '/actuator'
[demo] 2020-10-16 10:21:23.956  INFO 9 --- [  restartedMain] o.s.b.d.a.OptionalLiveReloadServer       : LiveReload server is running on port 35729
[demo] 2020-10-16 10:21:23.963  INFO 9 --- [  restartedMain] o.s.b.web.embedded.netty.NettyWebServer  : Netty started on port(s): 8080
[demo] 2020-10-16 10:21:23.964  INFO 9 --- [  restartedMain] com.example.demo.DemoApplication         : Started DemoApplication in 0.169 seconds (JVM running for 147.075)
[demo] 2020-10-16 10:21:23.965  INFO 9 --- [  restartedMain] .ConditionEvaluationDeltaLoggingListener : Condition evaluation unchanged
```