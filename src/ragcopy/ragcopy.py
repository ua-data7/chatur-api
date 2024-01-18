#!/usr/bin/env python3

import argparse
import logging
import os
import os.path
import time

from irods.session import iRODSSession

def parse_args():
    """
    Parses command-line arguments.
    """
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--src", help="the path to the source collection in the data store", required=True
    )
    parser.add_argument(
        "--dest", help="the path to the local destination directory", required=True
    )
    parser.add_argument(
        "--irods-user", help="the username used to log into the data store", default="anonymous"
    )
    parser.add_argument(
        "--irods-pass", help="the passphrase used to log into the data store", default=""
    )
    parser.add_argument(
        "--irods-zone", help="the zone used to log into the data store", default="iplant"
    )
    parser.add_argument(
        "--irods-host", help="the host name to use when connecting to the data store", default="data.cyverse.org"
    )
    parser.add_argument(
        "--irods-port", help="the port number to use when connecting to the data store", type=int, default=1247
    )
    parser.add_argument(
        "--run-period", help="the number of seconds to wait between syncs", type=int, default=600
    )
    return parser.parse_args()

def create_irods_session(args):
    """
    Creates an iRODS session using connection and authentication settings from the command-line arguments.
    """
    return iRODSSession(
        host=args.irods_host, port=args.irods_port, user=args.irods_user, password=args.irods_pass, zone=args.irods_zone
    )

def copy_files(session, src, dest):
    """
    Copies files from a source collection in the data store to a local destination directory. This function doesn't
    currently attempt to ensure that the files are identical.
    """
    logging.info("checking %s", src.path)
    for col in src.subcollections:
        dest_subdir = os.path.join(dest, col.name)
        os.makedirs(dest_subdir, exist_ok=True)
        copy_files(session, col, dest_subdir)
    for data_object in src.data_objects:
        dest_file = os.path.join(dest, data_object.name)
        if not os.path.exists(dest_file):
            logging.info("copying %s to %s", data_object.path, dest_file)
            session.data_objects.get(data_object.path, dest_file)

def run_copy(args):
    """
    Runs a single copy operation.
    """
    try:
        with create_irods_session(args) as session:
            src_coll = session.collections.get(args.src)
            copy_files(session, src_coll, args.dest)
    except Exception as e:
        logging.error("unable to copy the vector databases: %s", e)

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s:")
    args = parse_args()
    while True:
        logging.info("sync begin")
        run_copy(args)
        logging.info("sync end")
        time.sleep(args.run_period)
