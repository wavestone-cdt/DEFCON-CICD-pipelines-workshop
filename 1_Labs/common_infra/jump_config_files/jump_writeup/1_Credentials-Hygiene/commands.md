## Trufflehog
### The --rules option allows you to specify the regex used to detect password. Feel free to add your own within the provided regexes.json file.
trufflehog --regex --rules regexes.json https://{PLACEHOLDER_LAB_NAME}-gitlab.devsecoops.academy/public-resources/[REPLACE_THIS_WITH_A_PROJECT_NAME] --entropy=false
