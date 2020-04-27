
## Update national reports
source("utils/update_report_templates.R")

## Update all posts
source("utils/update_posts.R")

## Update the website
rmarkdown::render_site()

## Clean up nowcast folders
source("utils/clean_built_site.R")