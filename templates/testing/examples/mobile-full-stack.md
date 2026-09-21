# Example — Mobile qualification

Capability: **user uploads a video, approves processing, and the video appears in discovery**.

Required evidence: Android/iOS build/install/launch; upload with dedicated test account; backend media + processing record; terminal processing state; approval changes authoritative status; discovery API returns item; second session/device sees it; denied permissions/interrupted upload/processing failure are exercised; failures appear in logs.

Use Maestro for durable cross-platform journeys and Appium/Mobile Next for deeper native/device control. A UI assertion such as "Approved" is PARTIAL until backend/discovery state is independently observed.
