# Pull vs. Push
Monitoring systems generally belong to one of two distinct models: Those where services push metrics and logs into the system,
and those where the system actively queries services for metrics and logs. both have their advantages and disadvantages, but it mainly
comes down to personal preference.

In a pull based system, the monitoring system initiates the transfer. The system inherently knows all services available, and polls these
services at a regular interval. This results in a very consistent dataset where all timestamps line up almost perfectly which makes working
with your data lot easier. One of the disadvantages is that the system needs to know which services are available, which might complicate
things when working with distributed (dynamic) workloads.

In a push based system, the services themselves are responsible for initiating the transfer and deciding which metrics are important. This
moves the responsibility towards the maintainers of this system, which arguably is closer to a DevOps approach. The advantage of this is that
it's easier to scale (less work is done in a central hub of the system). It will also makes adding new services easier, as the system will not
have to be reconfigured everytime a services appears or disappears. It does however adds some complexity to the system, as the services need
to be able to discover the endpoints for the monitoring system.

One key difference will be noticable when considering the availability of your services. In a pull based system it's quite obvious when a service
becomes unavailable, as the monitoring system knows exactly which services should be there. When the process of fetching metrics fails it implies
that the service is unavailable. In a push based (distributed) model metric streams will appear and disappear quite regularly, so another approach
has to be considered for availability detection.

This reference implementation uses a push based model for one simple reason: it's what I already use, so it's most beneficial for me to create
this example. 
