#!/bin/bash
set -e
printf "\n"
printf "Checking tools...\n"
warnings=0
problems=0

# ---- Import Colors ---- #
SCRIPT_FOLDER=$( dirname ${BASH_SOURCE[0]})
source ${SCRIPT_FOLDER}/_colors_.sh

# Emojis:
#   ⚠️ - Warning
#   ❌ - Problem
#   ✅ - Success
#   🔎 - Inspecting
#   ▶️ - Of Note
#   🌐 - ?
#   🧮 - ? Calculation
#   🚨 - ?

check_tool(){
    tool_name=$1
    tool_cmd=$2
    version_cmd=$3
    recommended_version=$4
    install_instructions=$5

    printf "\n"
    printf "${CYAN}${tool_name}${NO_COLOR}...\n"
    if hash ${tool_cmd} 2>/dev/null; then
        if actual_version=$(bash -c "${version_cmd}"); then
            printf "    Version: ${actual_version}\n"
            if [[ ! "${actual_version}" == *"${recommended_version}"* ]]; then
                printf "        ${YELLOW}⚠️ WARNING: Version does not contain: ${recommended_version}${NO_COLOR}\n"
                warnings=$((warnings+1))
            fi
        else
            problems=$((problems+1))
            printf "    ${BRIGHT_RED}❌ PROBLEM: With '${tool_cmd}' - could not get version info!${NO_COLOR}\n"
        fi
    else
        problems=$((problems+1))
        printf "    ${BRIGHT_RED}❌ PROBLEM: '${tool_cmd}' command not found!${NO_COLOR}\n"
        if [[ ! -z ${install_instructions} ]]; then
            printf "    ▶️ To install run: ${BRIGHT_CYAN}${install_instructions}${NO_COLOR}\n"
        fi
    fi
}

check_aws_access(){
    printf "\n"
    printf "AWS Secret Access...\n"
    secret_id_to_check="local_dev/_env_files_/private.env"
    value_from_aws=""
    if hash aws 2>/dev/null; then
        if hash jq 2>/dev/null; then
            value_from_aws=$(aws secretsmanager describe-secret --secret-id ${secret_id_to_check} | jq -r .Name)
        fi
    fi
    if [[ ! "${secret_id_to_check}" == "${value_from_aws}" ]]; then
        problems=$((problems+1))
        printf "    * ${RED}PROBLEM: Unable to access AWS Secret: ${secret_id_to_check}${NO_COLOR}\n"
        printf "               You may need to run 'aws sso login'\n"
    else
        printf "    Success: Was able to retrieve secret's name: ${secret_id_to_check}\n"
    fi
}

check_docker_daemon_is_running(){
    if ! docker ps >/dev/null 2>&1; then
        printf "    ${BRIGHT_RED}❌ PROBLEM: Docker daemon is not running!${NO_COLOR}\n"
        printf "    ${CYAN}▶️ NOTE: Docker Desktop can be started from the terminal using: ${BRIGHT_CYAN}open -a docker${NO_COLOR}\n"
    fi
}

check_pyenv_versions(){
    if hash pyenv 2>/dev/null; then
        printf "    Required Python Version(s):\n"
        python_versions=$(pyenv versions)
        for version in "3.13.0" "3.13.0t"; do
            if [[ "${python_versions}" =~ "${version}" ]]; then
                printf "        ▶️ ${CYAN}${version} installed${NO_COLOR}\n"
            else
                printf "        ${YELLOW}⚠️ WARNING: a ${version} version needs to be installed (use: pyenv install ${version})${NO_COLOR}\n"
                warnings=$((warnings+1))
            fi
        done
    fi
}


if [[ "$(uname)" == "Darwin" ]]; then
    check_tool "Brew" "brew" "brew --version | head -n 1" "4.4"
    check_tool "xCode" "xcode-select" "xcode-select --version" "xcode-select version 2397"
else
	printf "Skipping Mac-specific tools (Brew, xCode)\n"
fi

# ---- Define the list of required / optional tools here ---- #
# check_tool "AWS Cli" "aws" "aws --version" "aws-cli/2.17" "brew install awscli"
# check_aws_access
check_tool "Docker" "docker" "docker --version" "version 27.3"
check_docker_daemon_is_running
check_tool "Git" "git" "git --version" "version 2.47" "brew install git"
# check_tool "jq " "jq" "jq --version" "jq-1.7" "brew install jq"
# check_tool "PipX" "pipx" "pipx --version" "1.7"
check_tool "Pyenv" "pyenv" "pyenv --version" "2.4" "brew install pyenv"
check_pyenv_versions
check_tool "Ruff" "ruff" "ruff --version" "ruff 0.7." "brew install ruff"
# check_tool "Tree (optional)" "tree" "tree --version" "v2.1" "brew install tree"
check_tool "uv" "uv" "uv version" "0.5" "curl -LsSf https://astral.sh/uv/install.sh | sh"


printf "\n\n"
printf "Done checking local tools:\n"
if [ ${warnings} -eq 1 ]; then
    printf "    Found: ${BRIGHT_YELLOW}⚠️ 1 Warning${NO_COLOR}\n"
elif [ ${warnings} -gt 0 ]; then
    printf "    Found: ${BRIGHT_YELLOW}⚠️ ${warnings} Warnings${NO_COLOR}\n"
else
    printf "    ${BRIGHT_GREEN}No Warnings${NO_COLOR}\n"
fi
if [ ${problems} -gt 0 ]; then
    printf "    Found: ${BRIGHT_RED}❌ ${problems} Problem(s)${NO_COLOR}\n"
    printf "\n"
    printf "PLEASE: Fix these before moving on!\n"
    printf "\n"
    exit -1
fi

printf "    ${BRIGHT_GREEN}No Problems${NO_COLOR}\n"
printf "\n"
date
printf "Done ($0).\n"
