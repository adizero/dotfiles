#!/usr/bin/env bash

declare -A mystocks
# mystocks[symbol]="price:shares"
# mystocks[GOOGL]="121.70:100"
# mystocks[AAPL]="162.87:12"
# mystocks[MSFT]="285.00:2"
# mystocks[NOK]="4.1147:2847.66"
mystocks[NOK]="3.9653:3290.02"

cash="1034.98"
mystocks[$]="0:1"

# fancy way how to distinguish whether first optional argument was a number
# if so consume it as interval, otherwise interval is set to 10 seconds
# cannot use set -e because the comparison will abort execution, since it is an error if $var is not a number
var="${1:-foo}"
[ -n "$var" ] && [ "$var" -eq "$var" ] 2>/dev/null
if [ $? -eq 0 ]; then
    interval="${var}"
    shift
else
    interval=10
fi

simple=1
t=2
log_file="/tmp/log_ticker"
log=1

toggle() {
    t=$(((t + 1) % 5))
}

trap "toggle" USR1

log_print() {
    if [ "${log}" -eq 1 ]; then
        d="$(date +%y%m%d_%H%M%S.%N)"
        if [ -n "${log_file}" ]; then
            echo "${d}: ${1}" >> "${log_file}"
        else
            echo "${d}: ${1}"
        fi
    fi
}

LANG=C
LC_NUMERIC=C

declare -a SYMBOLS
if [ "${1:-}" == "auto" ]; then
    SYMBOLS=("${!mystocks[@]}")
else
    SYMBOLS=("$@")
fi

if ! $(type jq > /dev/null 2>&1); then
  echo "'jq' is not in the PATH. (See: https://stedolan.github.io/jq/)"
  exit 1
fi

if [ -z "$SYMBOLS" ]; then
	echo "Usage: ./ticker.sh [<interval=10>] [<auto|stock symbols*>] (e.g. INTC GOOGL AAPL MSFT NOK BTC-USD)"
  exit
fi

declare -A current_price
declare -A stock_avg
declare -A stock_amount
declare -A stock_total

FIELDS=(symbol marketState regularMarketPrice regularMarketChange regularMarketChangePercent \
  preMarketPrice preMarketChange preMarketChangePercent postMarketPrice postMarketChange postMarketChangePercent)
API_ENDPOINT="https://query1.finance.yahoo.com/v7/finance/quote?lang=en-US&region=US&corsDomain=finance.yahoo.com"

if [ -z "$NO_COLOR" ]; then
  if [ "$simple" == "1" ]; then
    COLOR_BOLD="%%{F#ffffff}"
    COLOR_GREEN="%%{F#22ff22}"
    COLOR_RED="%%{F#ff2222}"
    COLOR_GRAY="%%{F#444444}"
    COLOR_RESET="%%{F-}"
  else
    : "${COLOR_BOLD:=\e[1;37m}"
    : "${COLOR_GREEN:=\e[32m}"
    : "${COLOR_RED:=\e[31m}"
    : "${COLOR_GRAY:=\e[38;5;239m}"
    : "${COLOR_RESET:=\e[00m}"
  fi
fi

symbols=$(IFS=,; echo "${SYMBOLS[*]}")
fields=$(IFS=,; echo "${FIELDS[*]}")

download_stock_market_data () {
    log_print "last stock market data download was ${delta}s ago DISPLAY [${t}]"
    download_cache_time="$current_time"
    results=$(curl --silent "$API_ENDPOINT&fields=$fields&symbols=$symbols" \
      | jq '.quoteResponse .result')
}

query () {
  echo $results | jq -r ".[] | select(.symbol == \"$1\") | .$2"
}

display_ticker () {
    log_print "DISPLAY [${t}]"
    last_display_time="$current_time"

    for key in ${!mystocks[@]}; do
      data="${mystocks[$key]}"
      stock_avg[$key]="${data%:*}"
      stock_amount[$key]="${data#*:}"
      stock_total[$key]="$(echo "scale=2; ${stock_avg[$key]} * ${stock_amount[$key]}" | bc -l)"
    done

    marketFlag=''
    pl=0

    for symbol in $(IFS=' '; echo "${SYMBOLS[*]}" | tr '[:lower:]' '[:upper:]'); do
        if [ "${symbol}" != "$" ]; then
            marketState="$(query $symbol 'marketState')"

            if [ -z $marketState ]; then
                printf 'No results for symbol "%s"\n' $symbol
                continue
            fi

            preMarketChange="$(query $symbol 'preMarketChange')"
            postMarketChange="$(query $symbol 'postMarketChange')"

            if [ $marketState == "PRE" ] \
                && [ $preMarketChange != "0" ] \
                && [ $preMarketChange != "null" ]; then
                nonRegularMarketSign='*'
                price=$(query $symbol 'preMarketPrice')
                diff=$preMarketChange
                percent=$(query $symbol 'preMarketChangePercent')
            elif [ $marketState != "REGULAR" ] \
                && [ $postMarketChange != "0" ] \
                && [ $postMarketChange != "null" ]; then
                nonRegularMarketSign='*'
                price=$(query $symbol 'postMarketPrice')
                diff=$postMarketChange
                percent=$(query $symbol 'postMarketChangePercent')
            else
                nonRegularMarketSign=''
                price=$(query $symbol 'regularMarketPrice')
                diff=$(query $symbol 'regularMarketChange')
                percent=$(query $symbol 'regularMarketChangePercent')
            fi
        else
            if [ ! "${t}" -eq 4 ]; then
                continue;
            fi
            price="${cash}"
            diff="${cash}"
            percent="0"
        fi

        if [ -z "${marketFlag}" ]; then
            if [ $marketState == "PRE" ]; then
                marketFlag='*'
            elif [ $marketState == "PREPRE" ]; then
                marketFlag='**'
            elif [ $marketState == "POST" ]; then
                marketFlag='*'
            elif [ $marketState == "POSTPOST" ]; then
                marketFlag='**'
            elif [ $marketState == "REGULAR" ]; then
                marketFlag=''
            elif [ $marketState == "CLOSED" ]; then
                marketFlag='#'
            else
                marketFlag="$marketState"
            fi
        fi

        if [ "$diff" == "0" ] || [ "$diff" == "0.0" ]; then
            color=
        elif ( echo "$diff" | grep -q ^- ); then
            color=$COLOR_RED
        else
            color=$COLOR_GREEN
        fi

        current_price[$symbol]=$price

        if [ "$price" != "null" ]; then
            if [ "$simple" == "1" ]; then
                if [ "${t}" -eq 0 ]; then 
                    if echo "${price} < 10" | bc -l &>/dev/null; then
                      fraction_digits=2
                    elif echo "${price} < 100" | bc -l &>/dev/null; then
                      fraction_digits=1
                    else
                      fraction_digits=0
                    fi
                    printf "$COLOR_GRAY${symbol:0:1}$color%.${fraction_digits}f$COLOR_RESET" $price
                elif [ "${t}" -eq 1 ]; then 
                    printf "$COLOR_GRAY${symbol:0:1}$color%.2f%%$COLOR_RESET" $percent
                elif [ "${t}" -eq 2 ]; then 
                    diff="$(echo "scale=2; ${current_price[$symbol]} * ${stock_amount[$symbol]:-0} - ${stock_total[$symbol]:-0}" | bc -l)"
                    if [ "$diff" == "0" ] || [ "$diff" == "0.0" ]; then
                        color=
                    elif ( echo "$diff" | grep -q ^- ); then
                        color=$COLOR_RED
                    else
                        color=$COLOR_GREEN
                    fi
                    printf "$COLOR_GRAY${symbol:0:1}$color%.0f$COLOR_RESET" $diff
                elif [ "${t}" -eq 3 ]; then 
                    total="${stock_total[$symbol]:-0}"
                    if [ "${total}" != "0" ]; then
                        diff="$(echo "scale=2; 100 * ${current_price[$symbol]} * ${stock_amount[$symbol]:-0} / ${total}" - 100 | bc -l)"
                    else
                        diff="0"
                    fi
                    if [ "$diff" == "0" ] || [ "$diff" == "0.0" ]; then
                        color=
                    elif ( echo "$diff" | grep -q ^- ); then
                        color=$COLOR_RED
                    else
                        color=$COLOR_GREEN
                    fi
                    printf "$COLOR_GRAY${symbol:0:1}$color%.2f%%$COLOR_RESET" $diff
                elif [ "${t}" -eq 4 ]; then 
                    diff="$(echo "scale=2; ${current_price[$symbol]} * ${stock_amount[$symbol]:-0} - ${stock_total[$symbol]:-0}" | bc -l)"
                    pl="$(echo "scale=2; ${pl} + ${diff}" | bc -l)"
                fi
            else
                printf "%-10s$COLOR_BOLD%8.2f$COLOR_RESET" $symbol $price
                printf "$color%10.2f%12s$COLOR_RESET" $diff $(printf "(%.2f%%)" $percent)
                printf " %s\n" "$nonRegularMarketSign"
            fi
        fi
    done
    if [ "$simple" == "1" ]; then
        if [ "${t}" -eq 4 ]; then
            diff="${pl}"
            if [ "$diff" == "0" ] || [ "$diff" == "0.0" ]; then
                color=
            elif ( echo "$diff" | grep -q ^- ); then
                color=$COLOR_RED
            else
                color=$COLOR_GREEN
            fi
            printf "$COLOR_GRAY\$$color%.0f$COLOR_RESET" $diff
        fi
        printf "$COLOR_GRAY$marketFlag$COLOR_RESET"
        echo
    fi
}

download_cache_time=0
last_display_time=0
old_t="$t"
i=0
while [ 1 ]; do
    if [ ! "$t" -eq "$old_t" ]; then
        # toggle was changed (user action), display refresh is needed
        old_t="$t"
        i=0
    fi
    if [ "$i" -eq 0 ]; then
        current_time=$(date +%s)
        delta=$((current_time - download_cache_time))
        if [ "$delta" -ge "$interval" ] || [ -z "$results" ]; then
            # time to refresh the cached data (always when no data were retrieved)
            download_stock_market_data
        fi
    
        display_ticker
    fi

    current_time=$(date +%s)
    min_time=$((last_display_time < download_cache_time ? last_display_time : download_cache_time))
    i=$((current_time - min_time))
    log_print "last refresh was ${i}s ago (interval ${interval}s)"
    if [ "$i" -ge "$interval" ]; then
        # sleep is over, refresh is needed
        i=0
    else
        # sleep the rest of the interval
        sleep $((interval - i)) &
        wait
    fi
done
