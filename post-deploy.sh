#!/bin/sh

#
# Post deploy script for a Ride installation.
# This script should be invoked from the root folder of your installation
#
# Usage: post-deploy.sh
# -e=<environment>   define the environment you are deploying
# -c                 skip clearing the cache
# -o                 skip orm define command
# -a                 skip assets deploy
# -w                 skip warm cache
#
# For example a post deploy for the stag environment
# ./post-deploy.sh -e=stag
#
# When exists, application/htaccess-stag will be copied to public/.htaccess
# The same for application/robots-stag which will be copied to public/robots.txt
#

# Initialize parameters
ENVIRONMENT="local"
PHP="php"
SKIP_CLEAR_CACHE=0
SKIP_ORM_DEFINE=0
SKIP_ASSETS_DEPLOY=0
SKIP_WARM_CACHE=0

# Gather parameters from arguments
for i in "$@"
do
    case $i in
        -e=*|--environment=*)
            ENVIRONMENT="${i#*=}"
            shift
        ;;
        -p=*|--php-version=*)
            PHP_VERSION="${i#*=}"
            shift
        ;;
        -c|--skip-clear-cache)
            SKIP_CLEAR_CACHE=1
            shift
        ;;
        -o|--skip-orm)
            SKIP_ORM_DEFINE=1
            shift
        ;;
        -a|--skip-assets)
            SKIP_ASSETS_DEPLOY=1
            shift
        ;;
        -w|--skip-warm-cache)
            SKIP_WARM_CACHE=1
            shift
        ;;
        *)
            # unknown option
        ;;
    esac
done

#
# Executes a command
# $1 Command to execute
# $2 Information message before the command
#
executeCommand() {
    echo $2
    $1
    if [ $? -ne 0 ]; then
        exit $?
    fi
}

executeCommand "composer install --no-dev" "Installing composer requirements..."
executeCommand "composer dump-autoload --optimize" "Optimizing autoloader"

if [ $SKIP_CLEAR_CACHE -eq 0 ]; then
    executeCommand "$PHP application/cli.php cache clear --skip=image" "Clearing cache..."
fi
if [ $SKIP_ASSETS_DEPLOY -eq 0 ]; then
    executeCommand "$PHP application/cli.php assets deploy" "Deploying assets..."
fi
if [ $SKIP_ORM_DEFINE -eq 0 ]; then
    executeCommand "$PHP application/cli.php orm define" "Define ORM models..."
fi
if [ $SKIP_WARM_CACHE -eq 0 ]; then
    executeCommand "$PHP application/cli.php cache warm" "Warming cache..."
fi

FILE="application/htaccess-$ENVIRONMENT"
if [ -f $FILE ]; then
    executeCommand "cp $FILE public/.htaccess" "Copying .htaccess file..."
fi

FILE="application/robots-$ENVIRONMENT"
if [ -f $FILE ]; then
    executeCommand "cp $FILE public/robots.txt" "Copying robots.txt file..."
fi

echo "Done"
