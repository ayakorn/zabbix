#!/usr/bin/env python3

"""
Script to provide information about send-receive times.

It must be run on a machine that is using the live database for the
Django ORM.
"""

import argparse
import os
import random
import sys
import time
import traceback
from typing import Any, Literal, NoReturn

sys.path.append(".")
sys.path.append("/home/zulip/deployments/current")
from scripts.lib.setup_path import setup_path
from scripts.lib.zulip_tools import atomic_nagios_write

setup_path()

import django
import zulip

sys.path.append("/home/zulip/deployments/current")
os.environ["DJANGO_SETTINGS_MODULE"] = "zproject.settings"

django.setup()

from django.conf import settings

from zerver.models.realms import get_realm
from zerver.models.users import get_system_bot
from zproject.config import get_config

usage = """Usage: send-receive.py [options] [config]

       'config' is optional, if present will return config info.
        Otherwise, returns the output data."""

parser = argparse.ArgumentParser(usage=usage)
parser.add_argument("--site", default=f"https://{settings.NAGIOS_BOT_HOST}")
parser.add_argument("--insecure", action="store_true")

options = parser.parse_args()


def report(
    state: Literal["ok", "warning", "critical", "unknown"],
    timestamp: float | None = None,
    msg: str | None = None,
) -> NoReturn:
    if msg is None:
        msg = f"send time was {timestamp}"
    print(f"check_send_receive_state {state} {msg}")
#    sys.exit(atomic_nagios_write("check_send_receive_state", state, msg))


def send_zulip(sender: zulip.Client, message: dict[str, Any]) -> None:
    result = sender.send_message(message)
    if result["result"] != "success":
        report("critical", msg=f"Error sending Zulip, args were: {message}, {result}")


def get_zulips() -> list[dict[str, Any]]:
    global last_event_id
    res = zulip_recipient.get_events(queue_id=queue_id, last_event_id=last_event_id)
    if "error" in res.get("result", {}):
        report("critical", msg="Error receiving Zulips, error was: {}".format(res["msg"]))
    for event in res["events"]:
        last_event_id = max(last_event_id, int(event["id"]))
    # If we get a heartbeat event, that means we've been hanging for
    # 40s, and we should bail.
    if "heartbeat" in (event["type"] for event in res["events"]):
        report("critical", msg="Got heartbeat waiting for Zulip, which means get_events is hanging")
    return [event["message"] for event in res["events"]]


internal_realm_id = get_realm(settings.SYSTEM_BOT_REALM).id
if (
    get_config("machine", "deploy_type") == "staging"
    and settings.NAGIOS_STAGING_SEND_BOT is not None
    and settings.NAGIOS_STAGING_RECEIVE_BOT is not None
):
    sender = get_system_bot(settings.NAGIOS_STAGING_SEND_BOT, internal_realm_id)
    recipient = get_system_bot(settings.NAGIOS_STAGING_RECEIVE_BOT, internal_realm_id)
else:
    sender = get_system_bot(settings.NAGIOS_SEND_BOT, internal_realm_id)
    recipient = get_system_bot(settings.NAGIOS_RECEIVE_BOT, internal_realm_id)

zulip_sender = zulip.Client(
    email=sender.email,
    api_key=sender.api_key,
    verbose=True,
    insecure=options.insecure,
    client="ZulipMonitoring/0.1",
    site=options.site,
)

zulip_recipient = zulip.Client(
    email=recipient.email,
    api_key=recipient.api_key,
    verbose=True,
    insecure=options.insecure,
    client="ZulipMonitoring/0.1",
    site=options.site,
)

try:
    res = zulip_recipient.register(event_types=["message"])
    if "error" in res.get("result", {}):
        report("critical", msg="Error subscribing to Zulips: {}".format(res["msg"]))
    queue_id, last_event_id = (res["queue_id"], res["last_event_id"])
except Exception:
    report("critical", msg=f"Error subscribing to Zulips:\n{traceback.format_exc()}")
msg_to_send = str(random.getrandbits(64))
time_start = time.perf_counter()

send_zulip(
    zulip_sender,
    {
        "type": "private",
        "content": msg_to_send,
        "subject": "time to send",
        "to": recipient.email,
    },
)

complete = False
while not complete:
    messages = get_zulips()
    seconds_diff = time.perf_counter() - time_start
    for m in messages:
        if msg_to_send == m["content"]:
            zulip_sender.delete_message(m["id"])
            complete = True
            break

zulip_recipient.deregister(queue_id)

if seconds_diff > 12:
    report("critical", timestamp=seconds_diff)
if seconds_diff > 3:
    report("warning", timestamp=seconds_diff)
else:
    report("ok", timestamp=seconds_diff)
