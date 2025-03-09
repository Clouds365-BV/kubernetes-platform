## Business Case

The customer Drone Shuttles Ltd. is currently running their website on an outdated platform hosted in their own
datacenter. They are about to launch a new product that will revolutionize the market and want to increase their social
media presence with a blogging platform. During their ongoing modernization process, they decided they want to use the
Ghost Blog platform for their marketing efforts.
They do not know what kind of traffic to expect so the solution should be able to adapt to traffic spikes. It is
expected that during the new product launch or marketing campaigns there could be increases of up to 4 times the typical
load. It is crucial that the platform remains online even in case of a significant geographical failure. The customer is
also interested in disaster recovery capabilities in case of a region failure.
As Ghost will be a crucial part of the marketing efforts, the customer plans to have 5 DevOps teams working on the
project. The teams want to be able to release new versions of the application multiple times per day, without requiring
any downtime. The customer wants to have multiple separated environments to support their development efforts.
As they are also tasked with maintaining the environment they need tools to support their operations and help them with
visualizing and debugging the state of the environment..
The website will be exposed to the internet, thus the security team also needs to have visibility into the platform and
its operations. The customer has also asked for the ability to delete all posts at once using a serverless function.
You are tasked to deliver a Proof of Concept for their new website. Your role is to design and implement a solution
architecture that covers the previously mentioned requirements, using the major public cloud platform (AWS, GCP, Azure)
that you’re interviewing for. The solution should be optimized for costs and easy to maintain/develop in the future.
Please implement your solution using the public cloud platform that is mentioned in the position that you applied for.
E.g. if you applied for an AWS-role, your solution should also be on AWS.

## Acceptance Criteria

- The application should be able to scale depending on the load.
- There should be no obvious security flaws.
- The application must return consistent results across sessions.
- The implementation should be built in a resilient manner.
- Observability must be taken into account when implementing the solution.
- The deployment of the application and environment should be automated.
