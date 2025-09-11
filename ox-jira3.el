;;; ox-jira3.el --- JIRA Backend for Org Export Engine

;; Copyright (C) 2025 Wolfgang Mederle

;; Author: Wolfgang Mederle <jungleoutthere@mederle.de>
;; Version: 0.1
;; Keywords: outlines, hypermedia, wp
;; Homepage: https://github.com/MadEarl/ox-jira3.el
;; Package-Requires: ((org "8.3"))

;; Based on ox-jira https://github.com/stig/ox-jira.el written by Stig Brautaset.

;; This file is NOT part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This module plugs into the regular Org Export Engine and transforms Org
;; files to JIRA markup for pasting into JIRA tickets & comments.

;; In an Org buffer, hit `C-c C-e J j' to bring up *Org Export Dispatcher*
;; and export it as a JIRA buffer. I usually use `C-x h' to mark the whole
;; buffer, then `M-w' to save it to the kill ring (and global pasteboard) for
;; pasting into JIRA issues.

;;; Code:

(eval-when-compile (require 'cl-lib))
(require 'ox)
(require 'ox-publish)
(require 'subr-x)
;; (require 's)

;;; User Configurable Options

(defgroup ox-jira3-export nil
  "Options specific to JIRA export back-end."
  :tag "Org Export JIRA"
  :group 'org-export
  :version "24.4"
  :package-version '(ox-jira3 . "0.1"))

(defcustom ox-jira3-src-collapse-threshold 30
  "Minimum number of lines in a src block to set collapse=true in JIRA/Confluence {code} block."
  :group 'ox-export-jira
  :type '(integer))

(defcustom ox-jira3-src-supported-languages
  '("actionscript"
    "ada"
    "applescript"
    "c"
    "c#"
    "c++"
    "css"
    "erlang"
    "go"
    "groovy"
    "html"
    "haskell"
    "json"
    "java"
    "javascript"
    "lua"
    "nyan"
    "objc"
    "php"
    "perl"
    "python"
    "r"
    "ruby"
    "sql"
    "scala"
    "swift"
    "visualbasic"
    "xml"
    "yaml"
    "bash")
  "Supported languages for syntax highlighting."
  :group 'ox-export-jira
  :type '(list))

;; For really long source snippets or sections of logfiles JIRA
;; supports showing a preview, and /collapsing/ the rest. How much to
;; preview before collapsing the rest is up to individual taste, so
;; let's make it configurable.

(defcustom ox-jira3-override-headline-offset nil
  "Use this to override the (default) relative headline levels.

If you want to have the headings *real* heading level in
the Jira output when you export a subsection, use `0' here.

If you think the headings in Jira are too big by default, you
could set this to `2' to start headings at level 3."
  :group 'ox-export-jira
  :type 'integer)

;;; Defining Backend

(org-export-define-backend 'jira
  '((babel-call . (lambda (&rest args) (ox-jira3--not-implemented 'babel-call)))
    (body . (lambda (&rest args) (ox-jira3--not-implemented 'body)))
    (bold . ox-jira3-bold)
    (center-block . (lambda (&rest args) (ox-jira3--not-implemented 'center-block)))
    (clock . (lambda (&rest args) (ox-jira3--not-implemented 'clock)))
    (code . ox-jira3-code)
    (diary-sexpexample-block . (lambda (&rest args) (ox-jira3--not-implemented 'diary-sexpexample-block)))
    (drawer . (lambda (&rest args) (ox-jira3--not-implemented 'drawer)))
    (dynamic-block . (lambda (&rest args) (ox-jira3--not-implemented 'dynamic-block)))
    (entity . (lambda (&rest args) (ox-jira3--not-implemented 'entity)))
    (example-block . ox-jira3-example-block)
    (export-block . (lambda (&rest args) (ox-jira3--not-implemented 'export-block)))
    (export-snippet . (lambda (&rest args) (ox-jira3--not-implemented 'export-snippet)))
    (final-output . (lambda (&rest args) (ox-jira3--not-implemented 'final-output)))
    (fixed-width . ox-jira3-fixed-width)
    (footnote-definition . ox-jira3-footnote-definition)
    (footnote-reference . ox-jira3-footnote-reference)
    (headline . ox-jira3-headline)
    (horizontal-rule . ox-jira3-horizontal-rule)
    (inline-babel-call . (lambda (&rest args) (ox-jira3--not-implemented 'inline-babel-call)))
    (inline-src-block . (lambda (&rest args) (ox-jira3--not-implemented 'inline-src-block)))
    (inlinetask . (lambda (&rest args) (ox-jira3--not-implemented 'inlinetask)))
    (italic . ox-jira3-italic)
    (item . ox-jira3-item)
    (keyword . (lambda (&rest args) ""))
    (latex-environment . (lambda (&rest args) (ox-jira3--not-implemented 'latex-environment)))
    (latex-fragment . (lambda (&rest args) (ox-jira3--not-implemented 'latex-fragment)))
    (line-break . (lambda (&rest args) (ox-jira3--not-implemented 'line-break)))
    (link . ox-jira3-link)
    (node-property . (lambda (&rest args) (ox-jira3--not-implemented 'node-property)))
    (options . (lambda (&rest args) (ox-jira3--not-implemented 'options)))
    (paragraph . ox-jira3-paragraph)
    (parse-tree . (lambda (&rest args) (ox-jira3--not-implemented 'parse-tree)))
    (plain-list . ox-jira3-plain-list)
    (plain-text . ox-jira3-plain-text)
    (planning . (lambda (&rest args) (ox-jira3--not-implemented 'planning)))
    (property-drawer . (lambda (&rest args) (ox-jira3--not-implemented 'property-drawer)))
    (quote-block . ox-jira3-quote-block)
    (radio-target . ox-jira3-radio-target)
    (section . ox-jira3-section)
    (special-block . (lambda (&rest args) (ox-jira3--not-implemented 'special-block)))
    (src-block . ox-jira3-src-block)
    (statistics-cookie . ox-jira3-statistics-cookie)
    (strike-through . ox-jira3-strike-through)
    (subscript . ox-jira3-subscript)
    (superscript . ox-jira3-superscript)
    (table . ox-jira3-table)
    (table-cell . ox-jira3-table-cell)
    (table-row . ox-jira3-table-row)
    (target . (lambda (&rest args) (ox-jira3--not-implemented 'target)))
    (timestamp . ox-jira3-timestamp)
    (underline . ox-jira3-underline)
    (verbatim . ox-jira3-verbatim)
    (verse-block . (lambda (&rest args) (ox-jira3--not-implemented 'verse-block))))
;;  :filters-alist '((:filter-parse-tree . ox-jira3-fix-multi-paragraph-items))
  :options-alist '((:src-collapse-threshold nil nil ox-jira3-src-collapse-threshold))
  :menu-entry
  '(?J "Export to JIRA"
       ((?j "As JIRA buffer" ox-jira3-export-as-jira))))

;;; Internal Helpers

;; Because I'm adding support for things as I find I need it rather than
;; all in one go, let's put a big fat red marker in for things we have
;; not implemented yet, to avoid missing it.

(defun ox-jira3-jsonp (string)
  "Validates a JSON string."
  (condition-case nil
      (progn
        (json-read-from-string string)
        t)
    (error nil)))

(defun ox-jira3--intern-special-chars (string)
  "Translates whitespace operators to their ansi equivalents in string.
This means replacing '\n' with '\\n', '\t' with '\\t', and escaping quotes and backslashes"
  (cl-loop for (item replacement) in
           '(("\n" "\\\\n") ("\t" "\\\\t") ("\"" "\\\\\"")); ("\\" "\\\\\\\\") ) 
           with result = string do
           (setf result (replace-regexp-in-string item replacement result))
           finally (return result)))

(defun ox-jira3--unintern-special-chars (string)
  "Translate special characters to their unescaped equivalents in string.
This means replacing '\\n' with '\n' and '\\t' with '\t' and unescaping escaped characters."
  (cl-loop for (item replacement) in
           '(("\\\\n" "\n") ("\\\\t" "\t") ("\\\\\"" "\"")); ("\\\\\\\\" "\\"))
           with result = string do
           (setf result (replace-regexp-in-string item replacement result))
           finally (return result)))

(defun ox-jira3-make-adf-item (key value &optional nowrap)
  "Create a json property as string."
  ;; (message (cl-format nil "~a: ~a~%" key value))
  (cond ((or (eq key 'content)
         (eq key 'marks)
         (eq key 'attrs)
         (numberp value)
         nowrap)
         (cl-format nil  "\"~a\":~a" key value))
        (t (cl-format nil  "\"~a\":\"~a\"" key value))))

(defun ox-jira3-make-adf-object (&rest args)
  "Create a json object as string."
  (if args
      (cl-format nil "{~{~a~^,~}}"
               args)
    '()))

(defun ox-jira3-make-adf-vector (&rest args)
  "Create a json array as string"
  (if args
      (cl-format nil "[~{~a~^,~}]" args)
    "[]"))

(defun ox-jira3-make-adf-doc (&rest args)
  "Create an ADF document structure in lisp,
to be converted by json-encode."
  (let ((result 
         (s-trim
          (replace-regexp-in-string
           "}[ \\n\\t]*{" "},{" 
           (replace-regexp-in-string
            "\n" ""
            (ox-jira3-make-adf-object
             (ox-jira3-make-adf-item 'version 1)
             (ox-jira3-make-adf-item 'type "doc")
             (ox-jira3-make-adf-item
              'content (ox-jira3-make-adf-vector
                        (cl-format nil "~{~a~^,~}" args)))))))))
    (message (cl-format nil "~a" result))
    result))

(defun ox-jira3--fix-exporter-bug-with-emphasize-text (text-item)
  "The Org exporter omits whitespace after emphasized text.
Until this is fixed, add a whitespace to the emphasized text."
  (list (car text-item) (cons (cdar text-item) (concat (cdadr text-item) " "))))

(defun ox-jira3--not-implemented (element-type)
  "Replace anything we don't handle yet with a big red marker."
  (format "{color:red}Element of type '%s' not implemented!{color}" element-type))

;; I often use super^script and sub_script at the end of words, with
;; no whitespace immediately before it. JIRA doesn't support that, so
;; we have to fake it. This function makes simple text transforms
;; "embeddable" by preceding them with an empty anchor. 

(defun ox-jira3--text-transform-embeddable (transform-char contents)
  (concat "{anchor}" transform-char contents transform-char))

;;; Filters

;; Org support a single blank line between items in a list, but if we
;; export like that JIRA interprets it as multiple consecutive lists;
;; which is never what I want. We can fix this by removing the
;; "post-blank" after =items= (and =paragraphs= inside =items=) using
;; a filter.

(defun ox-jira3-fix-multi-paragraph-items (tree backend info)
  "Remove extra blank line between paragraphs in plain-list items.

TREE is the parse tree being exported.  BACKEND is the export
back-end used.  INFO is a plist used as a communication channel.

Assume BACKEND is `jira'."
  (org-element-map tree '(item paragraph src-block)
    (lambda (e)
      (org-element-put-property
       e :post-blank
       (if (or (eq (org-element-type e) 'item)
               (eq (org-element-type (org-element-property :parent e)) 'item))
           0 1))))
  ;; Return updated tree.
  tree)

;;; Transcode functions

;; These functions do the actual translation to JIRA format. I used
;; Atlassian's Text Formatting Notation Help page as a reference, cf
;; https://jira.atlassian.com/secure/WikiRendererHelpAction.jspa?section=all

(defun ox-jira3-bold (bold contents info)
  "Transcode BOLD from Org to JIRA.
CONTENTS is the text with bold markup. INFO is a plist holding
contextual information."
  (let ((obj (ox-jira3--fix-exporter-bug-with-emphasize-text (json-read-from-string contents))))
    (json-encode
     (append obj '((marks . [((type . "strong"))]))))))

;; For CODE elements we cannot use the contents; it is always nil.
(defun ox-jira3-code (code _contents info)
  (ox-jira3-make-adf-object
   (ox-jira3-make-adf-item 'type "text")
   (ox-jira3-make-adf-item 'text (cl-format nil "~a" (org-element-property :value code)))
   (ox-jira3-make-adf-item
    'marks
    (ox-jira3-make-adf-vector
     (ox-jira3-make-adf-object 
      (ox-jira3-make-adf-item 'type "code"))))))

(defun ox-jira3-example-block (example-block _contents info)
  "Transcode an EXAMPLE-BLOCK element from Org to Jira.
CONTENTS is nil.  INFO is a plist holding contextual
information."
  (when (org-string-nw-p (org-element-property :value example-block))
    (ox-jira3-make-adf-object
     (ox-jira3-make-adf-item 'type "blockquote")
     (ox-jira3-make-adf-item
      'content
      (ox-jira3-make-adf-vector
       (ox-jira3-make-adf-object
        (ox-jira3-make-adf-item 'type "paragraph")
        (ox-jira3-make-adf-item
         'content
         (ox-jira3-make-adf-vector
          (ox-jira3-make-adf-object 
           (ox-jira3-make-adf-item 'type "text")
           (ox-jira3-make-adf-item 'text (ox-jira3--intern-special-chars (org-export-format-code-default example-block info))))))))))))

(defun ox-jira3-fixed-width (fixed-width contents info)
  "Transcode an FIXED-WIDTH element from Org to Jira.
CONTENTS is nil.  INFO is a plist holding contextual
information."
  (ox-jira3-make-adf-object
   (ox-jira3-make-adf-item 'type "text")
   (ox-jira3-make-adf-item 'text (cl-format nil "~a" contents))
   (ox-jira3-make-adf-item
    'marks
    (ox-jira3-make-adf-vector
     (ox-jira3-make-adf-object
      (ox-jira3-make-adf-item 'type "code"))))))

;;;; Footnotes

;; Footnotes have two parts: the reference, and the definition.

(defun ox-jira3--footnote-anchor (element)
  (let ((label (org-element-property :label element)))
    (replace-regexp-in-string ":" "" label)))

(defun ox-jira3--footnote-ref (anchor)
  (replace-regexp-in-string "fn" "" anchor))

(defun ox-jira3-footnote-reference (footnote-reference contents info)
  "Transcode an FOOTNOTE-REFERENCE element from Org to Jira.
CONTENTS is nil.  INFO is a plist holding contextual
information."
  (let* ((anchor (ox-jira3--footnote-anchor footnote-reference))
         (ref (ox-jira3--footnote-ref anchor)))
    (format "{anchor:fnr%s}[^%s^|#fn%s]"
            anchor ref anchor)))

(defun ox-jira3-footnote-definition (footnote-definition contents info)
  "Transcode an FOOTNOTE-DEFINITION element from Org to Jira.
CONTENTS is nil.  INFO is a plist holding contextual
information."
  (let* ((anchor (ox-jira3--footnote-anchor footnote-definition))
         (ref (ox-jira3--footnote-ref anchor)))
    (format "{anchor:fn%s}[^%s^|#fnr%s] %s"
            anchor ref anchor contents)))

;;;; Headline

;; Headlines are a little bit more complex. I'm not even attempting to
;; support TODO labels and meta-information, just the straight-up
;; text. It would be nice to support the six standard levels of
;; headlines JIRA offers though.

;; Since the headline level is /relative/ rather than absolute, if the
;; exporter sees a =** second level= heading before it's seen a =*
;; first level= then the =** second level= will think it's a top-level
;; heading. That's a bit weird, but there you go.

(defun ox-jira3-headline (headline contents info)
  "Transcode a HEADLINE element from Org to JIRA.
CONTENTS is the contents of the headline, as a string.  INFO is
the plist used as a communication channel."
  (let* ((headline-info (if (eql ox-jira3-override-headline-offset nil)
                            info
                          (plist-put nil :headline-offset ox-jira3-override-headline-offset)))
         (level (org-export-get-relative-level headline headline-info))
         (title (org-export-data-with-backend
                 (org-element-property :title headline)
                 'jira info))
         (todo (and (plist-get info :with-todo-keywords)
                    (let ((todo (org-element-property :todo-keyword headline)))
                      (and todo (org-export-data todo info)))))
         (todo-type (and todo (org-element-property :todo-type headline)))
         (todo-text (if todo
                        (ox-jira3-make-adf-object
                         (ox-jira3-make-adf-item 'type "text")
                         (ox-jira3-make-adf-item 'text todo)
                         (ox-jira3-make-adf-item
                          'marks
                          (ox-jira3-make-adf-vector
                           (ox-jira3-make-adf-item 'type "textColor")
                           (ox-jira3-make-adf-item
                            'attrs
                            (ox-jira3-make-adf-object 
                             (ox-jira3-make-adf-item 'color (if (eq todo-type 'done)
                                                         "#82ef6d"
                                                       "#e12057")))))))
                      "")))
         (ox-jira3-make-adf-object
          (ox-jira3-make-adf-item 'type "heading")
          (ox-jira3-make-adf-item
           'attrs
           (ox-jira3-make-adf-object 
            (ox-jira3-make-adf-item 'level level)))
          (ox-jira3-make-adf-item
           'content
           (ox-jira3-make-adf-vector
            (format "%s%s" todo-text (s-trim title)))))))

(defun ox-jira3-horizontal-rule (horizontal-rule contents info)
  "Transcode a HORIZONTAL-RULE element from Org to JIRA."
  (ox-jira3-make-adf-object
   (ox-jira3-make-adf-item 'type "rule")))

(defun ox-jira3-italic (italic contents info)
  (let ((obj (ox-jira3--fix-exporter-bug-with-emphasize-text (json-read-from-string contents))))
    (json-encode
     (append obj '((marks . [((type . "em"))]))))))

;;;; List item

;; A list item. The JIRA format for nested lists follows. (You can
;; also mix ordered and unordered lists.)

;; : * item
;; : ** sub-item
;; : ** sub-item 2
;; : * item 2

;; The item element itself does not know what type it is: that is an
;; attribute of its parent, a plain-list element. We need to walk the
;; path of alternating plain-list and item nodes until there are no
;; more, and extract their type. The type list is used to create a
;; bullet string.

;; JIRA doesn't really have support for definition lists, so we fake
;; it with a bullet list and some bold text for the term.

(defun ox-jira3--list-type-path (item)
  (when (and item (eq 'item (org-element-type item)))
    (let* ((list (org-element-property :parent item))
           (list-type (org-element-property :type list)))
      (cons list-type (ox-jira3--list-type-path
                       (org-element-property :parent list))))))

(defun ox-jira3--bullet-string (list-type-path)
  (apply 'string
         (mapcar (lambda (x) (if (eq x 'ordered) ?# ?*))
                 list-type-path)))

(defun ox-jira3-item (item contents info)
  "Transcode ITEM from Org to JIRA.
CONTENTS is the text with item markup. INFO is a plist holding
contextual information."
  (let* ((list-type-path (ox-jira3--list-type-path item))
         (tag (let ((tag (org-element-property :tag item)))
                (when tag
                  (org-export-data tag info))))
         (checkbox (cl-case (org-element-property :checkbox item)
                     (on "(/)")
                     (off "(x)")
                     (trans "(i)"))))
    (ox-jira3-make-adf-object
     (ox-jira3-make-adf-item 'type "listItem")
     (ox-jira3-make-adf-item 
      'content
      (ox-jira3-make-adf-vector contents)))))

(defun ox-jira3-radio-target (radio-target contents info)
  "Transcode a RADIO-TARGET object from Org to JIRA.
CONTENTS is nil. INFO is a plist holding contextual information."
  (let ((value (org-element-property :value radio-target)))
    (format "{anchor:%s}" value)))

;; JIRA supports many types of links. I don't expect to support them
;; all, but we must make a token effort. A lot of this code is cribbed
;; from =ox-latex.el=.

(defun ox-jira3-link (link desc info)
  "Transcode a LINK object from Org to JIRA.

DESC is the description part of the link, or the empty string.
INFO is a plist holding contextual information.  See
`org-export-data'."
  (let* ((type (org-element-property :type link))
         (raw-path (org-element-property :path link))
         (desc (and (not (string= desc "")) desc))
         (path (cond
                ((member type '("http" "https" "ftp" "mailto" "doi"))
                 (concat type ":" raw-path))
                ((string-prefix-p "~accountid" raw-path)
                 raw-path)
                ((string= type "file")
                 (org-export-file-uri raw-path))
                ((string= type "custom-id")
                 (if desc (concat "#" desc) (concat "#" raw-path)))
                ((string-prefix-p "*" raw-path)
                 (concat "#" (seq-subseq raw-path 1)))
                ((string= type "radio")
                 (concat "#" raw-path))
                ((org-export-custom-protocol-maybe link desc 'jira info))
                (t raw-path))))
    (cond
     ;; account-ids are mentions
     ((string-prefix-p "~accountid" raw-path)
      (ox-jira3-make-adf-object
       (ox-jira3-make-adf-item 'type "mention")
       (ox-jira3-make-adf-item
        'attrs
        (ox-jira3-make-adf-object
         (ox-jira3-make-adf-item 'id (replace-regexp-in-string "~accountid:" "" path))
         (ox-jira3-make-adf-item 'text (concat "@" (alist-get 'text (json-read-from-string desc))))))))
     (t
      (ox-jira3-make-adf-object
       (ox-jira3-make-adf-item 'type "text")
       (if desc
           (ox-jira3-make-adf-item 'text (alist-get 'text (json-read-from-string desc)))
         (ox-jira3-make-adf-item 'text path))
       (ox-jira3-make-adf-item
        'marks
        (ox-jira3-make-adf-vector
         (ox-jira3-make-adf-object
          (ox-jira3-make-adf-item 'type "link")
          (ox-jira3-make-adf-item
           'attrs
           (ox-jira3-make-adf-object
            (ox-jira3-make-adf-item 'href path)))))
        t))))))

(defun ox-jira3-underline (underline contents info)
  "Transcode UNDERLINE from Org to JIRA.
CONTENTS is the text with underline markup. INFO is a plist holding
contextual information."
  (let ((obj (ox-jira3--fix-exporter-bug-with-emphasize-text (json-read-from-string contents))))
    (json-encode
     (append obj '((marks . [((type . "underline"))]))))))

(defun ox-jira3-verbatim (verbatim _contents info)
  "Transcode a VERBATIM object from Org to Jira.
CONTENTS is nil.  INFO is a plist used as a communication
channel."
    (ox-jira3-make-adf-object
     (ox-jira3-make-adf-item 'type "text")
     (ox-jira3-make-adf-item 'text (cl-format nil "~a" (org-element-property :value verbatim)))
     (ox-jira3-make-adf-item
      'marks
      (ox-jira3-make-adf-vector
       (ox-jira3-make-adf-object 
        (ox-jira3-make-adf-item 'type "code"))))))

;; One of the most annoying aspects of JIRA markup is its broken
;; handling of line breaks; any newlines in the source becomes hard
;; linebreaks in the rendered output. We need to replace /internal/
;; newlines (i.e. any not at the end of the string) with a space.

(defun ox-jira3-paragraph (paragraph contents info)
  "Transcode a PARAGRAPH element from Org to JIRA.
CONTENTS is the contents of the paragraph, as a string.  INFO is
the plist used as a communication channel."
  (ox-jira3-make-adf-object
   (ox-jira3-make-adf-item 'type "paragraph")
   (ox-jira3-make-adf-item
    'content
    (ox-jira3-make-adf-vector
     (ox-jira3--unintern-special-chars contents))
    t )))

;; Lists are simple to support since all the complexity is in the code
;; for list item.

(defun ox-jira3-plain-list (plain-list contents info)
  "Transcode PLAIN-LIST from Org to JIRA.
CONTENTS is the text with plain-list markup. INFO is a plist holding
contextual information."
  (ox-jira3-make-adf-object
   (ox-jira3-make-adf-item 'type "bulletList")
   (ox-jira3-make-adf-item
    'content
    (ox-jira3-make-adf-vector contents))))

;; This is text with no markup, but we have to escape certain
;; characters to avoid tripping up JIRA. In particular:

;; - ={= :: Introduces macros
;; - =[= :: Introduces links

(defun ox-jira3-plain-text (text info)
  "Transcode TEXT from Org to JIRA.
TEXT is the string to transcode. INFO is a plist holding
contextual information."
  (ox-jira3-make-adf-object
   (ox-jira3-make-adf-item 'type "text")
   (ox-jira3-make-adf-item 'text (ox-jira3--unintern-special-chars text))))

;; Paragraphs are grouped into sections. I've not found any mention in
;; the Org documentation, but it appears to be essential for any
;; export to happen. I've essentially cribbed this from =ox-latex.el=.

(defun ox-jira3-section (section contents info)
  "Transcode a SECTION element from Org to JIRA.
CONTENTS is the contents of the section, as a string.  INFO is
the plist used as a communication channel."
  (ox-jira3-make-adf-doc contents))

;; If language is not member of =ox-jira3-src-supported-languages=,
;; =none=, will be used which I imagine will be a bit like
;; ={noformat}=.

(defun ox-jira3-src-block (src-block contents info)
  "Transcode a SRC-BLOCK element from Org to Jira.
CONTENTS holds the contents of the src-block.  INFO is a plist holding
contextual information."
  (when (org-string-nw-p (org-element-property :value src-block))
    (let* ((title (apply #'concat (org-export-get-caption src-block)))
           (lang (org-element-property :language src-block))
           (lang (if (member lang ox-jira3-src-supported-languages) lang "none"))
           (code (org-export-format-code-default src-block info)))
      (ox-jira3-make-adf-object 
       (ox-jira3-make-adf-item 'type "codeBlock")
       (ox-jira3-make-adf-item
        'attrs
        (ox-jira3-make-adf-object 
         (ox-jira3-make-adf-item 'language lang)))
       (ox-jira3-make-adf-item
        'content
        (ox-jira3-make-adf-vector
         (ox-jira3-make-adf-object
          (ox-jira3-make-adf-item 'type "text")
          (ox-jira3-make-adf-item 'text (json-serialize (s-trim code)) t))))))))

(defun ox-jira3-subscript (subscript contents info)
  "Transcode SUBSCRIPT from Org to JIRA.
CONTENTS is the text with subscript markup. INFO is a plist holding
contextual information."
  (let ((obj (ox-jira3--fix-exporter-bug-with-emphasize-text (json-read-from-string contents))))
    (json-encode
     (append obj '((marks . [((type . "subsup") (attrs (type . "sub")))]))))))

(defun ox-jira3-superscript (superscript contents info)
  "Transcode SUPERSCRIPT from Org to JIRA.
CONTENTS is the text with superscript markup. INFO is a plist holding
contextual information."
  (let ((obj (ox-jira3--fix-exporter-bug-with-emphasize-text (json-read-from-string contents))))
    (json-encode
     (append obj '((marks . [((type . "subsup") (attrs (type . "sup")))]))))))

;;;; Tables

;; Org's table editor is one of the many reasons to use Org; it is
;; excellent. Org and JIRA's tables are quite similar. Where Org marks
;; tables up like this:

;; : | Name   | Score |
;; : |--------+-------|
;; : | Ashley |     2 |
;; : | Alex   |     3 |

;; Jira uses the following format:

;; : || Name  || Score ||
;; : | Ashley | 2 |
;; : | Alex   | 3 |

;; Tables are complex beasts. I only hope to support simple ones.
;; Looks like most of the logic will live in the row and cell
;; transcoding functions.

(defun ox-jira3-table (table contents info)
  "Transcode a TABLE element from Org to JIRA.
CONTENTS holds the contents of the table.  INFO is a plist holding
contextual information."
  (ox-jira3-make-adf-object
   (ox-jira3-make-adf-item 'type "table")
   (ox-jira3-make-adf-item
    'content
    (ox-jira3-make-adf-vector contents))))

;; We only want to output =standard= rows, not horizontal lines. I'm
;; not sure if detection of header rows belong here or in the cells.

(defun ox-jira3-table-row (table-row contents info)
  "Transcode a TABLE-ROW element from Org to JIRA.
CONTENTS holds the contents of the table-row.  INFO is a plist holding
contextual information."
  (when (eq 'standard (org-element-property :type table-row))
    (ox-jira3-make-adf-object
     (ox-jira3-make-adf-item 'type "tableRow")
     (ox-jira3-make-adf-item
      'content
      (ox-jira3-make-adf-vector contents)))))

;; The cell itself does not know if it is a header cell or not, so we
;; have to ask its containing row if it is the first row, and the
;; table if it has a header row at all. If those things are true, make
;; the cell a header cell.

(defun ox-jira3-table-cell (table-cell contents info)
  "Transcode a TABLE-CELL element from Org to JIRA.
CONTENTS holds the contents of the table-cell.  INFO is a plist holding
contextual information."
  (let* ((row (org-element-property :parent table-cell))
         (table (org-element-property :parent row))
         (has-header (org-export-table-has-header-p table info))
         (group (org-export-table-row-group row info))
         (is-header (and has-header (eq 1 group))))
    (ox-jira3-make-adf-object
     (ox-jira3-make-adf-item 'type (if is-header "tableHeader" "tableCell"))
     (ox-jira3-make-adf-item
      'content
      (ox-jira3-make-adf-vector
       (ox-jira3-make-adf-object 
        (ox-jira3-make-adf-item 'type "paragraph")
        (ox-jira3-make-adf-item
         'content
         (ox-jira3-make-adf-vector 
          (cl-format nil "~a" (if contents contents ""))))))))))

;; This is updated to show progress of subsequent list of check boxes.

(defun ox-jira3-statistics-cookie (statistics-cookie _contents _info)
  "Transcode a STATISTICS-COOKIE object from Org to JIRA.
CONTENTS is nil.  INFO is a plist holding contextual information."
  (format "\\%s" (org-element-property :value statistics-cookie)))

;; JIRA call this "deleted text". In my opinion this is rather silly
;; because it is obviously there. Org is at least logical in calling
;; it for what it is. I suppose JIRA is trying to be semantic here,
;; but outside a diff you rather want to look in the revision log for
;; deleted text rather than have it clutter up things. Still, it's
;; simple to support, so we might as well do it.

(defun ox-jira3-strike-through (strike-through contents info)
  "Transcode STRIKE-THROUGH from Org to JIRA.
CONTENTS is the text with strike-through markup. INFO is a plist holding
contextual information."
  (let ((obj (ox-jira3--fix-exporter-bug-with-emphasize-text (json-read-from-string contents))))
    (json-encode
     (append obj '((marks . [((type . "strike"))]))))))

(defun ox-jira3-quote-block (quote-block contents info)
  "Transcode a QUOTE-BLOCK element from Org to Jira.
CONTENTS holds the contents of the block.  INFO is a plist
holding contextual information."
  (format "{quote}\n%s{quote}" contents))

(defun ox-jira3-timestamp (timestamp _contents info)
  "Transcode a TIMESTAMP object from Org to JIRA.
CONTENTS is nil. INFO is a plist holding contextual information."
  (let ((value (org-timestamp-translate timestamp))
        (fmt (cl-case (org-element-property :type timestamp)
               ((active active-range) "_%s_")
               ((inactive inactive-range) "_\\%s_")
               (otherwise "_%s_"))))
    (format fmt value)))

;;;###autoload
(defun ox-jira3-export-as-jira
    (&optional async subtreep visible-only body-only ext-plist)
  "Export current buffer as a Jira buffer.

If narrowing is active in the current buffer, only export its
narrowed part.

If a region is active, export that region.

A non-nil optional argument ASYNC means the process should happen
asynchronously.  The resulting buffer should be accessible
through the `org-export-stack' interface.

When optional argument SUBTREEP is non-nil, export the sub-tree
at point, extracting information from the headline properties
first.

When optional argument VISIBLE-ONLY is non-nil, don't export
contents of hidden elements.

When optional argument BODY-ONLY is non-nil, omit header
stuff. (e.g. AUTHOR and TITLE.)

EXT-PLIST, when provided, is a property list with external
parameters overriding Org default settings, but still inferior to
file-local settings.

Export is done in a buffer named \"*Org JIRA Export*\", which
will be displayed when `org-export-show-temporary-export-buffer'
is non-nil."
  (interactive)
  (org-export-to-buffer 'jira "*Org JIRA Export*"
    async subtreep visible-only body-only ext-plist))

(provide 'ox-jira3)

;;; ox-jira3.el ends here
