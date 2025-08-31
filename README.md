# MajorTom

> "Ground control to Major Tom" - David Bowie

OTP focused satellite mission control simulator.

> [!NOTE]
> This is just for fun and learning purposes and not reflection of a production system nor a reflection of the actual domain.

This exists for two reasons:

1. Explore a problem space for my own learning
2. To really leverage OTP for fun and demonstration purposes

The goal of this project is to simulate the distributed nature of communication
between an operator's console, a ground station, and a satellite.

## Usage

```elixir
MajorTom.start_link([])

satellite_call_sign = "jolly"

MajorTom.connect(satellite_call_sign)
MajorTom.init_orbit(satellite_call_sign)
```

## High level architecture

This project aims to simulate a ground control system for satellite operators.
It purposely uses OTP heavily as way to show case how one may architect these systems
in a complete OTP style. 

Another thing to note is the API for each domain aims to hide the complexities of the
OTP system and effectively abstracts OTP away. In my opinion, good OTP code is hidden
abstractions so the call sites do not need to know about process and how those are managed.

For this exercise, I decided to add three layers:

1. The main operator (this is the top level `MajorTom` module)
2. The ground station API. This simulates a ground station API that handles the communication
between a satellite and ground operators
3. A satellite simulation runtime called `MajorTom.Satellites.SatelliteEngine` to simulate a satellite

While in OTP I could drop the second layer, I want to add it to illustrate how these
systems can actually be built
