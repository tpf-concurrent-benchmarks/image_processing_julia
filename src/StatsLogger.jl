module StatsLogger

using Sockets

# Statsd Config

# Statsd Client from https://github.com/glenn-m/Statsd.jl/blob/38ad7bb0b6b40af3ea711e4efc506072a99b32a7/src/Statsd.jl
# MIT License: https://github.com/glenn-m/Statsd.jl/blob/38ad7bb0b6b40af3ea711e4efc506072a99b32a7/LICENSE

mutable struct Client
    host::IPv4
    port::Integer
    sock::IO
    prefix::String
    function Client(host::String="localhost", port::Integer=8125, prefix="")
        host = getaddrinfo(host)
        sock = UDPSocket()
        new(host, port, sock, prefix)
    end
end

## Send the metrics
function sc_send(sc::Client, data::String)
    send(sc.sock, sc.host, sc.port, data)
end

## Generate the metric and call send func
function sc_metric(sc::Client, type, metric, value, rate)
  if rate == nothing
      sc_send(sc, (isempty(sc.prefix) ? "" : "$(sc.prefix).") * "$metric:$value|$type")
  else
      sc_send(sc, (isempty(sc.prefix) ? "" : "$(sc.prefix).") * "$metric:$value|$type@$rate")
  end
end

## Counter Functions
sc_incr(sc::Client, metric, rate=nothing) = sc_metric(sc, "c", metric, 1, rate)
sc_decr(sc::Client, metric, rate=nothing) = sc_metric(sc, "c", metric, -1, rate)

## Gauge, Timers, and Set
sc_gauge(sc::Client, metric, value, rate=nothing) = sc_metric(sc, "g", metric, value, rate)
sc_timing(sc::Client, metric, value, rate=nothing) = sc_metric(sc, "ms", metric, value, rate)
sc_set(sc::Client, metric, value, rate=nothing) = sc_metric(sc, "s", metric, value, rate)


# Statsd Client Instance and module functions

statsd_client = nothing

function initialize( host::String, port::Integer, prefix::String )
  global statsd_client = Client(host, port, prefix)
end

function gauge( metric::String, value::Number )
  sc_gauge(statsd_client, metric, value)
end

function increment( metric::String, value::Number = 1)
  sc_incr(statsd_client, metric, value)  
end

function runAndMeasure( f::Function, metric::String )
  start = time()
  res = f()
  elapsed = time() - start
  sc_timing(statsd_client, metric, elapsed)
  return res
end

end