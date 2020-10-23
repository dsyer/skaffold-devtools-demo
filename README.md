# Devtools in Kubernetes

How would you get a Spring Boot app running in Kubernetes in development mode, where it can quickly restart if there are changes to the source code? You want to keep your default settings and binary artifacts optimized for production, so you don't want to add Devtools to the build, but you want it to kick in when you ask it to, even if the app is running in a cluster.

Spring Boot has its [Devtools](https://docs.spring.io/spring-boot/docs/1.5.16.RELEASE/reference/html/using-boot-devtools.html) feature, but that works best if the app is running in the same place as the code is being edited. You could run the IDE in the cluster, and that's possible with things like [Code Server](https://github.com/cdr/code-server). If we wanted to stick with a local IDE though, Skaffold has a [file sync](https://skaffold.dev/docs/pipeline-stages/filesync/) feature. Could that work with Devtools?

## Preparation

Get `kind` running locally and a local registry on port 5000, e.g. using the utility script in this repo:

```
src/build/kind-setup.sh
```

Set up the default builder:

```
pack set-default-builder paketobuildpacks/builder:full
```

and then make a builder:

```
pack create-builder -c builder/builder.toml localhost:5000/packs/java
```

Push the image into the repository so it can be used by other tools (like `skaffold`):

```
docker push localhost:5000/packs/java
```

## Build an Image

```
pack build demo --builder localhost:5000/packs/java
```

Run it:

```
docker run --entrypoint "/cnb/process/dev" -p 8080:8080 demo
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

It also works with `skaffold debug`, but remember to add an explicit `--auto-sync` to the command line. E.g:


```
skaffold debug --auto-sync --port-forward -p dev
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