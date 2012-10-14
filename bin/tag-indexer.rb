#!/usr/bin/env ruby
# gollum-wiki-tag-indexer - Processes a directory of Gollum wiki files updating 
# special "tag" pages with a list of pages that contain that tag.
#===============================================================================

# QUICK-START INSTRUCTIONS
# ------------------------
#
# 0. If you haven't already, clone the git repository containing your wiki.
#    E.g., if you're on GitHub, use something like:
#
#          git clone git@github.com:<USER>/<REPO>.wiki.git <LOCAL-REPO-DIR>
#
# 1. Update the gollum repo:
#
#          cd <LOCAL-REPO-DIR> && git pull
#
# 2. Run this script:
#
#          ruby gollum-wiki-tag-indexer.rb
#
#    Now every page with a name like `TagFoo` should be updated with a list of
#    pages that contain the text `[[TagFoo]]`.
#
# 3. Check what was updated:
#
#          git diff
#
#    (or `git status`)
#
# 4. Commit it if it looks good:
#
#          git commit -am "auto-indexed tags"
#
# Many of the naming patterns are configurable. Use the `--help` flag
# for details.
#
# See the comment at end this file for additional information.
#
 
require 'optparse'
require 'find'
require 'fileutils'

# These `LIST_*` variables tell us where to add the auto-generated index.
LIST_BEGIN = "<!-- THE LIST BELOW IS PROGRAMMATICALLY GENERATED. DO NOT REMOVE THIS COMMENT. -->"
LIST_END   = "<!-- THE LIST ABOVE IS PROGRAMMATICALLY GENERATED. DO NOT REMOVE THIS COMMENT. -->"
LIST_RE = Regexp.new("#{LIST_BEGIN}(.*)#{LIST_END}",Regexp::MULTILINE)

options = { :tagpattern => "(tag:[^\\]]+)",  :wikifilepattern => "^\./(.+)\.(md|wiki)$", :directory => ".", :metatag => "tag:index"  }

opt_parser = OptionParser.new do |opt|
  opt.banner = "Usage: #{$0} [OPTIONS]"
  opt.separator  ""
  opt.separator  "OPTIONS"

  opt.on("-d","--directory DIRECTORY","directory containing gollum wiki files [currently: \"#{options[:directory]}\"]") do |directory|
    options[:directory] = directory
  end

  opt.on("-t","--tagpattern PATTERN","regexp matching tag names [currently: \"#{options[:tagpattern]}\"]") do |pattern|
    options[:tagpattern] = pattern
  end

  options[:tagfilepattern] = "^\./#{options[:tagpattern]}\.(md|wiki)$"
  opt.on("-f","--tagfilepattern PATTERN","regexp matching tag file names [currently: \"#{options[:tagfilepattern]}\"]") do |pattern|
    options[:tagfilepattern] = pattern
  end

  opt.on("-w","--wikifilepattern PATTERN","regexp matching wiki file names [currently: \"#{options[:wikifilepattern]}\"]") do |pattern|
    options[:wikifilepattern] = pattern
  end

  opt.on("-m","--metatag","name of the meta tag page [currently: \"#{options[:metatag]}\"]") do |value|
    options[:metatag] = value
  end

  opt.on("-v","--verbose","be more chatty") do |pattern|
    options[:verbose] = true
  end

  opt.on("-s","--silent","be less chatty") do |pattern|
    options[:silent] = true
  end

  opt.on("-h","--help","show this help message then exit") do
    puts opt_parser
    options[:help] = true
  end
end

opt_parser.parse!

options[:verbose] = false if options[:silent]

puts "OPTIONS: #{options}" if options[:verbose]

def put(str) print str; STDOUT.flush; end # `put` immediately writes to STDOUT without a newline.

unless options[:help]

  puts "WIKI TAG INDEXER STARTING." unless options[:silent]
  puts "  Processing wiki directory at #{options[:directory]}" unless options[:silent]

  re_tagfile = Regexp.new(options[:tagfilepattern])
  re_wikifile = Regexp.new(options[:wikifilepattern])

  tags = {}
  files = {}

  puts "  Searching for wiki pages and tags..." unless options[:silent]
  FileUtils.cd("#{options[:directory]}",:verbose => true)
  Find.find("#{options[:directory]}") do |file|
    puts "file: #{file} #{options[:tagfilepattern]}" if options[:verbose]
    if re_tagfile.match(file)
      puts "    Found tag file... #{file}" if options[:verbose]
      tags[$1] = { :file => file, :re => Regexp.new("\\[\\[#{$1}\\]\\]",Regexp::MULTILINE), :hits => [] }
    end
    if re_wikifile.match(file)
       puts "    Found wiki file... #{file}" if options[:verbose]
       files[file] = $1
    end
  end
  puts "Found #{files.count} wiki pages and #{tags.count} tags." unless options[:silent]

  puts "  Indexing tag references...." if options[:verbose]
  hit_count = tagged_page_count = 0
  files.each_pair { |filename,label|
    unless label == options[:metatag]
      open("#{options[:directory]}/#{filename}") { |f|
        text = f.read
        old_hit_count = hit_count
        tags.each_pair { |tag,t|
          if(t[:re].match(text))
            t[:hits].push(label)
            hit_count += 1
          end
        }
        tagged_page_count += 1 if hit_count > old_hit_count
      }
    end
  }
  puts "Found #{hit_count} distinct tag references across #{tagged_page_count} pages. " unless options[:silent]

  puts "  Writing indices to tag pages...." if options[:verbose]
  index_added = 0
  index_updated = 0
  tags.each_pair { |tag,t|
    newlist = LIST_BEGIN
    newlist += "\n\n"
    if tag == options[:metatag]
      newlist += tags.keys.reject { |p| p == options[:metatag] }.sort.map { |p| " * [[#{p.gsub('-',' ')}]]\n" }.join
    else
      newlist += t[:hits].sort.map { |p| " * [[#{p.gsub('-',' ')}]]\n" }.join
    end
    newlist += "\n"
    newlist += LIST_END
    open("#{options[:directory]}/#{t[:file]}") { |f|
      text = f.read
      unless text.gsub!(LIST_RE, newlist)
        text += newlist
        index_added +=1
      else
        index_updated +=1
      end
      File.open("#{options[:directory]}/#{t[:file]}",'w') { |g| g.write(text) }
    }
  }
  puts "Tag index added to #{index_added} pages, updated on #{index_updated}." unless options[:silent]
  puts "WIKI TAG INDEXING COMPLETE." unless options[:silent]
end


#===============================================================================
#
# CONTEXT & MOTIVATIONS
# ---------------------
#
# GitHub (optionally) hosts a wiki for each repository.  These wikis are
# supported by a git-backed wiki engine called
# [Gollum](https://github.com/github/gollum/).
#
# Gollum offers a web interface for publishing and editing wiki pages.
# Behind the scenes these pages are stored in a Git repository as
# text files (in Markdown or similar simple-text-markup formats).
#
# Currently, GitHub's wikis (and, I assume, Gollum wikis in general) do not
# support search or cross-referencing functions. If, for example, you want
# a list of all the pages that link to (reference) the current page, you'd
# be forced to use a site-specific Google search or to `grep` a local
# mirror of the underlying git repository.
#
# A common wiki-usage-pattern that depends upon this kind of "live" search
# capability is "tag" or "category" pages.  Following this pattern, pages
# that share some characteristic can be "tagged" by adding a wiki-link to
# a particular page.  E.g., on Wikipedia editors add a link to
# `Category:France` to tag pages about France.
# Searching for [pages that include that link](http://en.wikipedia.org/wiki/Special:WhatLinksHere/Category:France)
# then provides an automatically-updated, manually-created index of all
# Wikipedia pages related to France.
#
# We'd like the ability to do something similar. This script makes it easier.
#
#
#
# WHAT IT DOES
# ------------
#
# This script examines every file in the specified directory (option `-d`).
#
# Files that match the specified tag name pattern (option `-f`) are
# considered to be "tag pages" (and the tag-name sub-expression
# (option `-t`) is considered to be the tag name).
#
# Files that match the specified wiki file pattern (option `-w`) are
# considered to be "wiki pages". Wiki pages will be searched for
# tag references. (Note that a file can be both a tag page and a wiki
# page.)
#
# We search the wiki pages to assemble, for each tag, a list of pages
# that contain links of the form `[[TagName]]`.
#
# Finally we update each tag page with a list of pages that link to it.
# (The list is inserted into the section delimited by the HTML comments
# specified in `LIST_BEGIN` and `LIST_END`. If this section is not found,
# one will be added.)
#
# The "meta-tag" page (specified by option `-m`) is a notable exception
# to the standard processing.  The meta-tag page (by default, `TagTag`)
# is considered to be a tag that marks other tag pages. It is handled
# in two special ways:
#
#  1. The meta-tag  page will be updated with a list of all other tag
#     pages--whether or not they actually contain the `[[TagTag]]` tag.
#
#  2. Tags found on the meta-tag page will be ignored--they will not
#     appear in the automatically generated indices.
#
#
#
# ADDITIONAL NOTES & COMMENTS
# ---------------------------
#
#  * Although Gollum supports other markup formats, this script currently
#    assumes all pages are written with the  Markdown syntax. Relaxing
#    that assumption would be a nice enhancement to this script.
#
#  * This script assumes tag links always take the form `[[TagName]]`.
#    That may or may not always be appropriate, even within Markdown-based
#    wiki pages.
#
#  * More generally, there are a handful of values that one may want to
#    to override that are not exposed as configuration parameters.
#    These include the `LIST_*` delimiters, the `[[TagName]]` tag
#    reference format and the logic that creates a label from a
#    wiki page name (e.g., replacing `-` with ` `).
#
#  * This script will only "discover" tags that have a corresponding
#    wiki page. We might consider working in the other direction,
#    identifying all links of the form `[[TagName]]` and generating
#    the corresponding `TagName.md` file if it doesn't already exist.
#
#  * Conceivably the Gollum API could be used to allow this script to
#    read and write directly against the wiki's web interface (rather
#    than requiring a local `git pull`/`git commit`/`git push` process).
#
#  * Alternatively, it might be handy to close the loop on this script
#    by including the `git pull` and `git push` logic directly. That
#    would allow this script to be a "complete solution" that could
#    be dropped into a crontab or something like that.
#
#  * (Obviously?) one could generalize the logic of this script to
#    generate a "list of all pages that link to this one" for an
#    arbitrary wiki page, not just "tag pages".
#
#===============================================================================

