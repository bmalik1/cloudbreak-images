#!/bin/bash

set -x

echo '{}' | jq --arg sb "$(salt-bootstrap --version | awk '{print $2}')" '. + {"salt-bootstrap": $sb}' > /tmp/package-versions.json
cat /tmp/package-versions.json | jq --arg sv "$($SALT_PATH/bin/salt-call --local grains.get saltversion --out json | jq -r .local)" '. + {"salt": $sv}' > /tmp/package-versions.json

cat /tmp/package-versions.json | jq --arg git_rev ${GIT_REV} '. + {"cloudbreak_images": $git_rev}' > /tmp/package-versions.json.tmp && mv /tmp/package-versions.json.tmp /tmp/package-versions.json

cat /tmp/package-versions.json | jq --arg inverting_proxy_agent_version "$(jumpgate-agent --version | awk 'NR==1{print $3}')" '. + {"inverting-proxy-agent": $inverting_proxy_agent_version}' > /tmp/package-versions.json
JUMPGATE_AGENT_GBN_REGEX=".*\/([0-9]+)\/.*"
if [[ $JUMPGATE_AGENT_RPM_URL =~ $JUMPGATE_AGENT_GBN_REGEX ]]; then
    cat /tmp/package-versions.json | jq --arg inverting_proxy_agent_gbn ${BASH_REMATCH[1]} '. + {"inverting-proxy-agent_gbn": $inverting_proxy_agent_gbn}' > /tmp/package-versions.json.tmp && mv /tmp/package-versions.json.tmp /tmp/package-versions.json
fi

if [[ "$CDP_TELEMETRY_VERSION" != "" ]]; then
	cat /tmp/package-versions.json | jq --arg cdp_telemetry_version $CDP_TELEMETRY_VERSION -r '. + {"cdp-telemetry": $cdp_telemetry_version}' > /tmp/package-versions.json.tmp && mv /tmp/package-versions.json.tmp /tmp/package-versions.json
fi

if [[ "$CDP_LOGGING_AGENT_VERSION" != "" ]]; then
	cat /tmp/package-versions.json | jq --arg cdp_logging_agent_version $CDP_LOGGING_AGENT_VERSION -r '. + {"cdp-logging-agent": $cdp_logging_agent_version}' > /tmp/package-versions.json.tmp && mv /tmp/package-versions.json.tmp /tmp/package-versions.json
fi

for package in "$@"
do
	if [ "$package" != "None" ]; then
		cat /tmp/package-versions.json | jq --arg p "$package" --arg v "$($SALT_PATH/bin/salt-call --local pkg.version $package --out json | jq -r .local)" '. + {($p): $v}' > /tmp/package-versions.json
	fi
done

if [[ "$CUSTOM_IMAGE_TYPE" == "freeipa" ]]; then
	FREEIPA_REGEX=".*\/[_a-z\-]*\-(.*)\.x86_64\.rpm"
	if [[ $FREEIPA_PLUGIN_RPM_URL =~ $FREEIPA_REGEX ]]; then
		cat /tmp/package-versions.json | jq --arg freeipa_plugin_version ${BASH_REMATCH[1]} '. + {"freeipa-plugin": $freeipa_plugin_version}' > /tmp/package-versions.json.tmp && mv /tmp/package-versions.json.tmp /tmp/package-versions.json
	fi
	if [[ $FREEIPA_HEALTH_AGENT_RPM_URL =~ $FREEIPA_REGEX ]]; then
		cat /tmp/package-versions.json | jq --arg freeipa_health_agent_version ${BASH_REMATCH[1]} '. + {"freeipa-health-agent": $freeipa_health_agent_version}' > /tmp/package-versions.json.tmp && mv /tmp/package-versions.json.tmp /tmp/package-versions.json
	fi
elif [[ "$CUSTOM_IMAGE_TYPE" == "hortonworks" ]]; then
	METERING_REGEX=".*\/[_a-z\-]*\-(.*)\-.*\.x86_64\.rpm"
	if [[ $METERING_AGENT_RPM_URL =~ $METERING_REGEX ]]; then
		cat /tmp/package-versions.json | jq --arg metering_agent_version ${BASH_REMATCH[1]} '. + {"metering_agent": $metering_agent_version}' > /tmp/package-versions.json.tmp && mv /tmp/package-versions.json.tmp /tmp/package-versions.json
	fi
fi

chmod 744 /tmp/package-versions.json

exit 0
