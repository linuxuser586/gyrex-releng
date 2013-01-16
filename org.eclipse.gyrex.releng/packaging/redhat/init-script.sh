#!/bin/bash
#
# @daemonname@ @daemonsummary@
#
# chkconfig:   35 90 10
# description: @daemondescription@
#
###############################################################################
# Copyright (c) 2012 AGETO Service GmbH, Oracle Corporation and others.
# All rights reserved.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License v1.0 which accompanies this distribution,
# and is available at http://www.eclipse.org/legal/epl-v10.html.
#
# Contributors:
#     Pascal Bleser - initial API and implementation for Eclipse Hudson
#     Gunnar Wagenknecht - generalized for Java based processes 
###############################################################################

### BEGIN INIT INFO
# Provides:          @daemonname@
# Required-Start:    $local_fs $remote_fs $network $time $named
# Should-Start:      sendmail
# Required-Stop:     $local_fs $remote_fs $network $time $named
# Should-Stop:       sendmail
# Default-Start:     3 5
# Default-Stop:      0 1 2 6
# Short-Description: @daemonsummary@
# Description:       Start the @daemonsummary@
### END INIT INFO

# the service name (used for display and customizations)
SERVICE_NAME="@daemonname@"
SERVICE_TITLE="@daemonsummary@"

# service configuration
SERVICE_USER=@user@
SERVICE_GROUP=@group@
SERVICE_CONFIG="/etc/sysconfig/${SERVICE_NAME}"
SERVICE_PID_FILE="/var/run/${SERVICE_NAME}.pid"

# Source function library.
. /etc/rc.d/init.d/functions

# Check for existence of needed config file and read it
test -e "$SERVICE_CONFIG" || { echo "$SERVICE_CONFIG not existing";
  if [ "$1" = "stop" ]; then exit 0;
  else exit 6; fi; }
test -r "$SERVICE_CONFIG" || { echo "$SERVICE_CONFIG not readable. Perhaps you forgot 'sudo'?";
  if [ "$1" = "stop" ]; then exit 0;
  else exit 6; fi; }

# Make sure we run as root, since setting the max open files through
# ulimit requires root access
if [ `id -u` -ne 0 ]; then
    echo "The ${SERVICE_NAME} init script can only be run as root"
    exit 1
fi

# Source customizations
. "${SERVICE_CONFIG}"

# check for the servce command to daemonize
[ -z "$SERVICE_CMD" ] || { echo "SERVICE_CMD not configured in ${SERVICE_CONFIG}";
  if [ "$1" = "stop" ]; then exit 0;
  else exit 6; fi; }

SERVICE_LOCK_FILE="/var/lock/subsys/${SERVICE_NAME}"
RETVAL=0

do_start() {
  # make sure user can write to pid file
  test -e "${SERVICE_PID_FILE}" || touch $SERVICE_PID_FILE > /dev/null
  chown "${SERVICE_USER}:${SERVICE_GROUP}" $SERVICE_PID_FILE > /dev/null

  # generate launch script
  TMP_LAUNCHER_DIR=$(mktemp -dt "${SERVICE_NAME}-XXXXXXXXXX")
  TMP_LAUNCHER="${TMP_LAUNCHER_DIR}/launchhelper.${SERVICE_NAME}.sh"
  echo '#!/bin/sh' > $TMP_LAUNCHER
  echo "${SERVICE_CMD}" >> $TMP_LAUNCHER
  echo "echo \$! > ${SERVICE_PID_FILE}" >> $TMP_LAUNCHER
  chown $SERVICE_USER -R $TMP_LAUNCHER_DIR > /dev/null
  chmod u+x $TMP_LAUNCHER > /dev/null
  
  # start service
  echo -n "Starting ${SERVICE_TITLE} "
  daemon --check "${SERVICE_NAME}" --user "${SERVICE_USER}" --pidfile "${SERVICE_PID_FILE}" $TMP_LAUNCHER
  RETVAL=$?
  
  # cleanup
  rm -rf $TMP_LAUNCHER_DIR > /dev/null
  
  # create lock file on success
  if [ $RETVAL = 0 ]; then
    success
	touch "${SERVICE_LOCK_FILE}"
  else
    failure
  fi

  echo
  return $RETVAL
}

do_stop() {
  # start service
  echo -n "Shutting down ${SERVICE_TITLE} "
  killproc -p "${SERVICE_PID_FILE}" -d 30 "${SERVICE_NAME}"
  RETVAL=$?

  # remove lock file on success
  if [ $RETVAL = 0 ]; then
    success
	rm -f "${SERVICE_LOCK_FILE}"
  else
    failure
  fi

  echo
  return $RETVAL
}

case "$1" in
  start)
    do_start
    ;;
  stop)
    do_stop
    ;;
  try-restart)
    $0 status
    if test $? = 0; then
        $0 restart
    else
        : # Not running is not a failure.
    fi
    ;;
  restart)
    do_stop
    do_start
    ;;
  status)
    status -p "${SERVICE_PID_FILE}" -l "${SERVICE_LOCK_FILE}" "${SERVICE_NAME}"
    RETVAL=$?
    ;;
  *)
    echo "Usage: $0 {start|stop|status|try-restart|restart}"
    exit 1
    ;;
esac
exit $RETVAL
