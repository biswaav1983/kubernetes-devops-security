#!/bin/bash
#cis-master.sh

total_fail=$(/usr/local/bin/kube-bench --config-dir /usr/local/bin/cfg --config /usr/local/bin/cfg/config.yaml run --targets master  --version 1.15 --check 1.2.7,1.2.8,1.2.9 --json | jq '.Totals | .total_fail')

if [[ "$total_fail" -ne 0 ]];
        then
                echo "CIS Benchmark Failed MASTER while testing for 1.2.7, 1.2.8, 1.2.9"
                exit 1;
        else
                echo "CIS Benchmark Passed for MASTER - 1.2.7, 1.2.8, 1.2.9"
fi;
