#!/bin/sh

#
# Post deploy script for a Ride installation
#

# Initialize parameters
ENVIRONMENT="local"
PHP="php"
SKIP_CACHE=0
SKIP_ORM=0
SKIP_ASSETS=0
WARM_CACHE=1

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
        -c|--skip-cache)
            SKIP_CACHE=1
            shift
        ;;
        -o|--skip-orm)
            SKIP_ORM=1
            shift
        ;;
        -a|--skip-assets)
            SKIP_ASSETS=1
            shift
        ;;
        -w|--warm-cache)
            WARM_CACHE=1
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

if [ $SKIP_CACHE -eq 0 ]; then
    executeCommand "$PHP application/cli.php cache clear --skip=image" "Clearing cache..."
fi
if [ $SKIP_ASSETS -eq 0 ]; then
    executeCommand "$PHP application/cli.php assets deploy" "Deploying assets..."
fi
if [ $SKIP_ORM -eq 0 ]; then
    executeCommand "$PHP application/cli.php orm define" "Define ORM models..."
fi
if [ $WARM_CACHE -eq 1 ]; then
    executeCommand "$PHP application/cli.php cache warm" "Warming cache..."
fi

$FILE="application/htaccess-$ENVIRONMENT"
if [ -f $FILE ]; then
    executeCommand "cp $FILE public/.htaccess" "Copying .htaccess file..."
fi

$FILE="application/robots-$ENVIRONMENT"
if [ -f $FILE ]; then
    executeCommand "cp $FILE public/robots.txt" "Copying robots.txt file..."
fi

echo "Done"
