# mesos-proxy
[![Docker Stars](https://img.shields.io/docker/pulls/mongey/mesos-proxy.svg)](https://hub.docker.com/r/mongey/mesos-proxy/)

Access logs of [Marathon](https://mesosphere.github.io/marathon/) tasks from the command line.

`main.go` A proxy server to access files from a mesos slaves sandbox.

`logs ` works with `main.go` allowing you to retrieve stdout / stderr from a
running Marathon task.

## Install

Build the server component

```
make
```

Install the binary on an accessible http server so that it's accessible @
`https://web-mesos-proxy.${HOST}`


If you have Marathon configured to expose services through a web server, you can
deploy mesos-proxy using the following config.

```json
{
  "id": "/mesos-proxy/web",
  "instances": 1,
  "cpus": 0.1,
  "mem": 100,
  "container": {
    "type": "DOCKER",
    "docker": {
      "image": "mongey/mesos-proxy:latest",
      "network": "BRIDGE",
      "portMappings": [
        {
          "containerPort": 8181,
          "protocol": "tcp",
          "name": "http"
        }
      ]
    }
  },
  "healthChecks": [
    {
      "protocol": "TCP",
      "portIndex": 0,
      "gracePeriodSeconds": 30,
      "intervalSeconds": 30,
      "timeoutSeconds": 10,
      "maxConsecutiveFailures": 3,
      "ignoreHttp1xx": false
    }
  ]
}
```

To retrieve logs you will need ruby installed, and to install the `httparty` gem
```
gem install httparty
```

## Usage

The `logs` script assumes that marathon is accessible via
`https://marathon.${HOST}` and that `mesos-log-proxy` is available at
`https://web-mesos-proxy.${HOST}`

```
HOST=my-host.com ./logs
```

Combine it with fzf to search through marathon tasks

```
export HOST=my-host.com
logs $(./logs | fzf)
```
