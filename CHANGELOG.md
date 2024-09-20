### 0.9.3 (2024-09-20)
- update `freeswitch-modules` to `1.2.30`
- update `freeswitch` to `1.10.12`
  - [mod_event_socket] Check if listener is running before pushing more logs or events to its queue
  - [mod_opus] Fix status returned by switch_opus_decode(). Should be SWITCH_STATUS_FALSE instead of SWITCH_STATUS_NOOP. Add a unit-test.
  - [mod_sofia] Set missing CF_3PCC flag
- update `cmake` to `3.30.3`
- update `gRPC` to `1.66.1`
- update `azure speech sdk` to `1.40.0`
- update `aws-sdk-cpp` to `1.11.409`

### 0.9.2 (2024-09-13)
- fix replacement in `entrypoint.sh` to set the `Mediaserver` name correctly via `--username`
- improve `build-locally.sh` and add a tag to the docker image with `repo:version` from `.env` file

### 0.9.1 (2024-06-08)
- update `freeswitch` to `1.10.11`
  - this changes the `sofia-sip` library requirement to version `1.13.17`
- update `aws-sdk-cpp` to `1.11.345`
- update `gRPC` to `1.64.2`
- improve `Dockerfile`
  All used versions for this build are now centralized in the `.env` file
- improve `Dockerfile` for `sofia-sip` and use tag instead of branch
- update the `docker-publish` pipeline to read and set the appropriate build args
- update `README` and add section of how to build the image locally
- add bash script `build-locally`