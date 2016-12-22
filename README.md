
## What is it?

This is a script that is a wrapper around [wfuzz](https://github.com/xmendez/wfuzz) that uses by default wordlists provided from [SecLists](https://github.com/danielmiessler/SecLists) and leveraging **John the Ripper** during custom wordlist generation.

The script has been implemented after tons of wfuzz, dirb and other dirbusting tools launching from command line by hand, with time spent to every time look on tools usage informations and choosing proper wordlist files to use this very time.

It is intended to be used for quick launch from command line during a penetration testing assignment, or some others type of web application scanning.


## Example usage:

Dirbusting of web application "www.example.com" with couple of custom words to be used for custom wordlist generation and with redefined HTTP Status codes to skip.

```
work|21:11|~/tools/dirbust # ./dirbuster.sh -H "301,302,401,404,410" \
		-c example,backup,test,database,db -o ~/work/example/logs/dirbust1.txt www.example.com

	.:: wfuzz and SecLists based dirbusting script ::.
	    To be used for quick dir busting pentest task
	    Mariusz B. / 16', v0.1

[?] Generated additional 224 words

** Stage 0: Custom wordlist scan.
Scanning with custom provided wordlist...

== Running forceful browsing scan
- Hide HTTP codes:	301,302,401,404,410
- Start time:		czw, 22 gru 2016, 21:11:50 CET
- Number:		1
- URL pattern:		www.example.com/FUZZ
- List(s):		/tmp/dirbust.words.24526.22706.txt 
- Requests to make:	224
- Command line:		wfuzz -I -t 64 -s 0.02 -Z -c  --hc 301,302,401,404,410  -w /tmp/dirbust.words.24526.22706.txt  www.example.com/FUZZ
==

********************************************************
* Wfuzz 2.1.3 - The Web Bruteforcer                      *
********************************************************

Target: http://www.example.com/FUZZ
Total requests: 224

==================================================================
ID	Response   Lines      Word         Chars          Request    
==================================================================


Total time: 5.775265
Processed Requests: 224
Filtered Requests: 224
Requests/sec.: 38.78609


== Running forceful browsing scan
- Hide HTTP codes:	301,302,401,404,410
- Start time:		czw, 22 gru 2016, 21:11:56 CET
- Number:		2
- URL pattern:		www.example.com/FUZZFUZ2Z
- List(s):		/tmp/dirbust.words.24526.22706.txt /tmp/dirbust.extensions.small.2827.9476.txt
- Requests to make:	6272
- Command line:		wfuzz -I -t 64 -s 0.02 -Z -c  --hc 301,302,401,404,410  -w /tmp/dirbust.words.24526.22706.txt -w /tmp/dirbust.extensions.small.2827.9476.txt www.example.com/FUZZFUZ2Z
==

********************************************************
* Wfuzz 2.1.3 - The Web Bruteforcer                      *
********************************************************

Target: http://www.example.com/FUZZFUZ2Z
Total requests: 6272

...
```


## TODO

- Nothing at the moment.
