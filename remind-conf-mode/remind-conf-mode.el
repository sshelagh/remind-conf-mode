;;; remind-conf-mode.el --- A mode to help configure remind.

;; Copyright (C) 2009  Shelagh Manton <shelagh.manton@gmail.com>

;; Author: Shelagh Manton <shelagh.manton@gmail.com> with help from
;; David F. Skoll
;; Keywords: remind configure mode
;; Version: .04

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 2
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
;; 02111-1307, USA.

;;; Commentary:

;; Use this mode to help with the configuration of remind configuration files.
;; Put (require 'remind-conf-mode) in your .emacs file
;; or (autoload 'remind-conf-mode "remind-conf-mode" "Mode to help with remind files" t)
;; also put (add-to-list 'auto-mode-alist '("\\.rem\\'" . remind-conf-mode)) and
;; (setq auto-mode-alist
;;     (cons '(".reminders$" . remind-conf-mode) auto-mode-alist))
;; if you want to have the mode work automatically when you open a remind configuration file.

;; If you want to use the auto-complete stuff, you will need to download and install the
;; auto-complete library from  http://www.cx4a.org/pub/auto-complete.el and put
;; (require 'auto-complete) in your emacs with
;; (add-hook 'remind-conf-mode-hook
;;  (lambda ()
;;    (make-local-variable 'ac-sources)
;;    (setq ac-sources '(ac-remind-conf ))
;;    (auto-complete t)))
;;   in your .emacs file

;;   PS. you could add ac-source-abbrev ac-source-words-in-buffer to have abbrevs and
;;   other words in buffer auto-complete too

;;; History:
;; Thu, Feb 14, 2008
;; Based mode on wpld-mode tutorial and sample-mode on emacs wiki.
;; Ideas from mupad.el for font-lock styles.
;; Mon, Jan 26, 2008
;; Added rem-setup-colors to make it easy for colourised remind output.
;; Added a demo skeleton for people to copy for easy entry of coloured remind entries.
;; tried to hook in the auto-complete library so that all known functions and keywords can be easily entered.
;; EXPERIMENTAL, but seems to work well here (emacs cvs).
;; Seems to work without case folding which is nice. wonder why it didn't yesterday?

;;; Code:


(require 'font-lock); this goes in the define-derived-mode part.
(when (featurep 'xemacs)
  (require 'overlay)) ;I wonder if this will help with font-lock and xemacs?


(defgroup remind-conf nil
  "Options for remind-conf-mode."
  :group 'remind-conf
  :prefix "remind-conf-")

;; (defvar remind-conf-font-lock-keywords remind-conf-font-lock-keywords-3
;;   "Default highlighting for `remind-conf-mode'.")

(defvar remind-conf-mode-hook nil
  "Hook to run in `remind-conf-mode'.")

;; keymap

(defvar remind-conf-mode-map
  (let ((remind-conf-mode-map (make-sparse-keymap)))
    remind-conf-mode-map)
  "Keymap for `remind-conf-mode'.")

(define-key remind-conf-mode-map "\C-cr" 'rem-skel)
(define-key remind-conf-mode-map "\C-ct" 'rem-today)
(define-key remind-conf-mode-map "\C-cd" 'rem-today-skel)
(define-key remind-conf-mode-map "\C-cw" 'rem-week-away)
(define-key remind-conf-mode-map "\C-cx" 'rem-tomorrow)
(define-key remind-conf-mode-map "\C-ca" 'rem-days-away)

;; syntax-table

(defvar remind-conf-syntax-table
  (let ((remind-conf-syntax-table (make-syntax-table text-mode-syntax-table)))
					;Comments are the same as Lisp
    (modify-syntax-entry ?\; ". 1b" remind-conf-syntax-table)
    (modify-syntax-entry ?\# ". 1b" remind-conf-syntax-table)
    (modify-syntax-entry ?\n "> b" remind-conf-syntax-table)
					;Names with _ are still one word.
    (modify-syntax-entry ?_ "w" remind-conf-syntax-table)
    (modify-syntax-entry ?. "w" remind-conf-syntax-table)
    (modify-syntax-entry ?\( "()"  remind-conf-syntax-table)
    (modify-syntax-entry ?\) ")(" remind-conf-syntax-table)
    (modify-syntax-entry ?\[ "(]"  remind-conf-syntax-table)
    (modify-syntax-entry ?\] ")[" remind-conf-syntax-table)
    remind-conf-syntax-table)
  "Syntax table for `remind-conf-mode'.")

;; faces
;;example of setting up special faces for a mode.

(defvar remind-conf-command-face 'remind-conf-command-face
  "Remind commands.")
(defface remind-conf-command-face
  '((t :foreground "SeaGreen4" :bold t))
  "Font Lock mode face used to highlight commands."
  :group 'remind-conf)

(defvar remind-conf-keyword-face 'remind-conf-keyword-face
  "Remind keywords.")
(defface remind-conf-keyword-face
  '((t :foreground "blue violet"))
  "Font Lock mode face used to highlight keywords."
  :group 'remind-conf)

(defvar remind-conf-substitutes-face 'remind-conf-substitutes-face
  "Remind substitutes.")
(defface remind-conf-substitutes-face
  '((t :foreground "blue2"))
  "Font Lock mode face used to highlight substitutes."
  :group 'remind-conf)

(defvar remind-conf-endline-face 'remind-conf-endline-face
  "Remind endline.")
(defface remind-conf-endline-face
  '((t :foreground "goldenrod2" :bold t))
  "Font Lock mode face used to highlight commands."
  :group 'remind-conf)

(defvar remind-conf-variable-face 'remind-conf-variable-face
  "Remind variable.")
(defface remind-conf-variable-face
  '((t :foreground "DeepPink2" :bold t))
  "Font Lock mode face used to highlight commands."
  :group 'remind-conf)

(defvar remind-conf-color-face 'remind-conf-color-face
  "Remind color variables.")
(defface remind-conf-color-face
  '((t :foreground "gold" :bold t))
  "Font Lock mode face used to highlight color changes."
  :group 'remind-conf)

(defvar remind-conf-delta-face 'remind-conf-delta-face
  "Remind deltas.")
(defface remind-conf-delta-face
  '((t :foreground "sandy brown" :bold t))
  "Font Lock mode face used to highlight deltas."
  :group 'remind-conf)

(defvar remind-comment-face 'remind-comment-face
  "Remind comments.")
(defface remind-comment-face
  '((t :foreground "brown"))
  "Font-lock face for highlighting comments."
  :group 'remind-conf)

(defvar remind-string-face 'remind-string-face
  "Remind strings.")
(defface remind-string-face
  '((t :foreground "salmon"))
  "Font lock mode face used to highlight strings."
  :group 'remind-conf)

(defvar remind-time-face 'remind-time-face
  "Remind time words.")
(defface remind-time-face
  '((t :foreground "LightSeaGreen" :bold t))
  "Font lock mode face to highlight time phrases."
  :group 'remind-conf)

;; keywords

(defconst remind-conf-font-lock-keywords-1
  (list
   '("^[\;\#]\\s-+.*$" . remind-comment-face)
   '("\\<\\(CAL\\|FSET\\|MS[FG]\\|OMIT\\|PS\\(?:FILE\\)?\\|R\\(?:EM\\|UN\\)\\|S\\(?:ATISFY\\|ET\\|HADE\\|PECIAL\\)\\|TRIGGER\\)\\>" . remind-conf-keyword-face)
   '("%[\"_]" . font-lock-warning-face)
   '("\\(%[a-mops-w]\\)" . remind-conf-substitutes-face)
   '("\"[^\"]*\"" . remind-string-face))
  "Minimal font-locking for `remind-conf-mode'.")

(defconst remind-conf-font-lock-keywords-2
  (append remind-conf-font-lock-keywords-1
	  (list
	   '("\\<\\(A\\(?:PR\\(?:IL\\)?\\|UG\\(?:UST\\)?\\)\\|DEC\\(?:EMBER\\)?\\|FEB\\(?:RUARY\\)?\\|J\\(?:AN\\(?:UARY\\)?\\|U\\(?:LY\\|NE\\|[LN]\\)\\)\\|MA\\(?:RCH\\|[RY]\\)\\|NOV\\(?:EMBER\\)?\\|OCT\\(?:OBER\\)?\\|SEP\\(?:T\\(?:EMBER\\)?\\)?\\)\\>" . remind-time-face)

	   '("^SET\\s-+\\<\\(A\\(?:PR\\(?:IL\\)?\\|UG\\(?:UST\\)?\\)\\|DEC\\(?:EMBER\\)?\\|FEB\\(?:RUARY\\)?\\|J\\(?:AN\\(?:UARY\\)?\\|U\\(?:LY\\|NE\\|[LN]\\)\\)\\|MA\\(?:RCH\\|[RY]\\)\\|NOV\\(?:EMBER\\)?\\|OCT\\(?:OBER\\)?\\|SEP\\(?:T\\(?:EMBER\\)?\\)?\\)\\>" 1 remind-time-face)

	   '("^\\(FRI\\(?:DAY\\)?\\|MON\\(?:DAY\\)?\\|S\\(?:AT\\(?:URDAY\\)?\\|UN\\(?:DAY\\)?\\)\\|T\\(?:HU\\(?:R\\(?:S\\(?:DAY\\)?\\)?\\)?\\|UE\\(?:S\\(?:DAY\\)?\\)?\\)\\|WED\\(?:NESDAY\\)?\\)\\>" . remind-time-face)

	   '("\\<\\(FRI\\(?:DAY\\)?\\|MON\\(?:DAY\\)?\\|S\\(?:AT\\(?:URDAY\\)?\\|UN\\(?:DAY\\)?\\)\\|T\\(?:HU\\(?:R\\(?:S\\(?:DAY\\)?\\)?\\)?\\|UE\\(?:S\\(?:DAY\\)?\\)?\\)\\|WED\\(?:NESDAY\\)?\\)\\>" . remind-time-face)

	   '("^SET\\s-+\\<\\(FRI\\(?:DAY\\)?\\|MON\\(?:DAY\\)?\\|S\\(?:AT\\(?:URDAY\\)?\\|UN\\(?:DAY\\)?\\)\\|T\\(?:HU\\(?:R\\(?:S\\(?:DAY\\)?\\)?\\)?\\|UE\\(?:S\\(?:DAY\\)?\\)?\\)\\|WED\\(?:NESDAY\\)?\\)\\>" 1 remind-time-face)

	   '("\\<\\(A\\(?:FTER\\|T\\)\\|B\\(?:ANNER\\|EFORE\\)\\|DURATION\\|INCLUDE\\|ONCE\\|P\\(?:RIORITY\\|USH_OMIT_CONTEXT\\)\\|S\\(?:C\\(?:ANFROM\\|HED\\)\\|KIP\\)\\|TAG\\|UN\\(?:SET\\|TIL\\)\\|WARN\\)\\>" . remind-conf-command-face)
	   '("%$" . remind-conf-endline-face)))
  "Additional commands to highlight in `remind-conf-mode'.")

(defconst remind-conf-font-lock-keywords-3
  (append remind-conf-font-lock-keywords-2
	  (list
	   '("\\<\\(INT\\|STRING\\|TIME\\|DATE\\)\\>" . remind-conf-type-face )
	   '("\[[a-zA-Z]\\{3,6\\}\]" . remind-conf-color-face)
	   '("\\s-+\\([12][0-9]\\|3[01]\\|0?[0-9]\\)\\s-+" . remind-time-face);better date regexp
	   '("\\s-+\\(\\(?:20\\|19\\)[0-9][0-9]\\)\\s-+" . remind-time-face);years
	   '("\\s-+\\(2[0-4]\\|[01]?[0-9][.:][0-5][0-9]\\)\\s-+" . remind-time-face);24hour clock, more precise
	   '("\\s-+\\([+-][+-]?[1-9][0-9]*\\)\\s-+" 1 remind-conf-delta-face prepend)
	   '("\\<\$[A-Za-z]+\\>" . remind-conf-variable-face)))
  "The ultimate in highlighting experiences for `remind-conf-mode'.")

(defcustom remind-conf-font-lock-keywords 'remind-conf-font-lock-keywords-3
  "Font-lock highlighting level for `remind-conf-mode'."
  :group 'remind-conf
  :type '(choice (const :tag "Barest minimum of highlighting." remind-conf-font-lock-keywords-1)
		 (const :tag "Medium highlighting." remind-conf-font-lock-keywords-2)
		 (const :tag "Highlighting deluxe." remind-conf-font-lock-keywords-3)))


;; thank goodness we don't have to worry about indentation.
;; What about using omit?? this is a TODO.

(defcustom rem-indent 4
  "User definable indentation."
  :group 'remind-conf
  :type '(integer)
  )

(defun rem-indent-line ()
  "indent current line for remind configuration files."
  (interactive)
  (beginning-of-line)
  (if (bobp)
      (indent-line-to 0);Ok for now. need to set out rules.
;; 1. beginning of file indent to 0 [X]
    (let ((not-indented t) cur-indent)
      (when (looking-at "^[ \t]*\\<\\(ENDIF\\|POP-OMIT-CONTEXT\\)\\>")
	  (progn
	    (save-excursion
	      (forward-line -1)
	      (setq cur-indent 0))))
      (when (looking-at "\\<\\(IF\\(?:TRIG\\)?\\|PUSH\\(?:-OMIT-CONTEXT\\)?\\)\\>")
	  (progn
	    (save-excursion
	      (forward-line 1)
	      (setq cur-indent rem-indent))))
      (when (looking-at ""
	      )))))
;; 2. if at a endif or pop-to-context block unindent to zero [X] Maybe I should consider cond.
;; 3. if after a push-to-context or if* indent by rem-indent.
	
;; 4. all other cases don't indent.
(regexp-opt '("IF" "IFTRIG" "PUSH-OMIT-CONTEXT" "PUSH") 'words)

;;; setup for autocompletion

    ;; need the full list of keywords.

    (defconst remind-keywords 
      (sort 
       (list "RUN" "REM" "sort(" "ONCE" "SATISFY" "trigger(" "BEFORE" "ord(" "thisyear("
	     "OMIT" "DATE" "SKIP" "ONCE" "AFTER" "WARN" "PRIORITY" "AT" "SCHED" "IF" "ELSE" "ENDIF"
	     "WARN" "UNTIL" "SCANFROM" "DURATION" "TAG" "MSG" "MSF" "CAL" "SPECIAL" "IFTRIG" 
	     "PS" "PSFILE" "BANNER" "INCLUDE" "shell(" "PUSH-OMIT-CONTEXT" "DEBUG" "DUMPVARS"
	     "CLEAR-OMIT-CONTEXT" "POP-OMIT-CONTEXT" "INT" "STRING" "TIME" "DATE" "SET" "ERRMSG"
	     "EXIT" "FLUSH" "PRESERVE" "MOON" "COLOR"
	     "unset" "sunrise(" "sunset(" "$CalcUTC" "$CalMode" "$DefaultPrio" "$EndSent" "$EndSentIg"
	     "$FirstIndent" "$FoldYear" "$FormWidth" "$MinsFromUTC" "$LatDeg" "$LatMin" "$LatSec"
	     "$Location" "$LongDeg" "$LongMin" "$LongSec" "$MaxSatIter" "$SubsIndent" "abs(" "access("
	     "args(" "asc(" "baseyr(" "char(" "choose(" "coerce(" "date(" "dawn(" "today(" "day(" "daysinmon("
	     "defined(" "dosubst(" "dusk(" "easterdate(" "filedir(" "filename(" "getenv(" "hour(" "iif("
	     "index(" "isdst(" "isleap(" "isomitted(" "hebdate(" "hebday(" "hebmon(" "hebyear(" "language("
	     "lower(" "max(" "min(" "minute(" "mon(" "moondate(" "moontime(" "moonphase(" "now(" "ostype("
	     "plural(" "realnow(" "realtoday(" "sgn(" "strlen(" "substr(" "trigdate(" "trigger(" "trigtime("
	     "trigvalid(" "typeof(" "upper(" "value(" "version(" "wkday(" "wkdaynum(" )
       #'(lambda (a b) (> (length a) (length b)))))

    (defvar ac-remind-conf
      '((candidates
	 . (lambda ()
	     (all-completions ac-target remind-keywords))))
      "Source for remind-conf keywords.")

    ;; however I can do a couple of skeletons for convenience of new users.

    (define-skeleton rem-skel
      "Skeleton to insert a rem line in a remind configuration file."
      nil
      "REM "(skeleton-read "Date? " )
      ("Optional: How many days ahead? " " +" str )
      resume:
      ("Optional: At what time? Format eg 13:00. " " AT " str)
      resume:
      ("Optional: How many minutes ahead? " " +" str )
      resume:
      ("Optional: At what priority? eg 0-9999" " PRIORITY " str )
      resume:
      " MSG %\"" (skeleton-read "Your message? " )"%b%\"%" \n
      )

    (define-skeleton rem-today-skel
      "Skeleton to insert a line for today's date."
      nil
      "REM " (format-time-string "%d %b %Y")
      ("Optional: At what time? Format eg 13:20. " " AT " str)
      resume:
      ("Optional: How many minutes ahead? " " +" str )
      resume:
      ("Optional: At what priority? eg 0-9999" " PRIORITY " str )
      resume:
      " MSG " (skeleton-read "Your message? " )"%b.%" \n
      )

    (defun rem-today ()
      "Insert the date for today in a remind friendly style."
      (interactive)
      (insert (format-time-string "%e %b %Y")))

    (defun rem-tomorrow ()
      "Insert tomorrow's date in a remind friendly style."
      (interactive)
      (insert (format-time-string "%e %b %Y" (time-add (current-time) (days-to-time 1)))))

    (defun rem-days-away (arg)
      "Insert a day N number of days in the future.
Takes a prefix argument, but defaults to 4."
      (interactive "nHow many Days?: ")
      (insert (format-time-string "%e %b %Y" (time-add (current-time) (days-to-time arg)))))

    (defun rem-week-away ()
      "Insert a day 7 days in the future."
      (interactive)
      (insert (format-time-string "%e %b %Y" (time-add (current-time) (days-to-time 7)))))

    (setq skeleton-end-hook nil)

    (defun rem-setup-colors ()
      "Insert set of variables for coloured output in remind messages."
      (interactive)
      (find-file (expand-file-name "~/.reminders")
		 (goto-char 0)
		 (save-excursion
		   (re-search-forward "\n\n")
		   (insert "SET Esc   CHAR(27) \n
SET Nrm   Esc + \"[0m\" \n
SET Blk   Esc + \"[0;30m\" \n
SET Red   Esc + \"[0;31m\" \n
SET Grn   Esc + \"[0;32m\" \n
SET Ylw   Esc + \"[0;33m\" \n
SET Blu   Esc + \"[0;34m\" \n
SET Mag   Esc + \"[0;35m\" \n
SET Cyn   Esc + \"[0;36m\" \n
SET Wht   Esc + \"[0;37m\" \n
SET Gry   Esc + \"[30;1m\" \n
SET BrRed Esc + \"[31;1m\" \n
SET BrGrn Esc + \"[32;1m\" \n
SET BrYlw Esc + \"[33;1m\" \n
SET BrBlu Esc + \"[34;1m\" \n
SET BrMag Esc + \"[35;1m\" \n
SET BrCyn Esc + \"[36;1m\" \n
SET BrWht Esc + \"[37;1m\" \n"))))

    ;; So now you can do things like:

    (define-skeleton birthcol
      "Make birthdays magenta.
Acts on the region or places point where it needs to be."
      nil
      "[Mag]" _ " [Nrm]")

    ;; finally the derived mode.

;;;###autoload
    (define-derived-mode remind-conf-mode text-mode "remind-conf-mode"
      "Major mode for editing remind calendar configuration files."
      :syntax-table remind-conf-syntax-table
      (set (make-local-variable 'font-lock-defaults) '(remind-conf-font-lock-keywords))
      (set (make-local-variable 'font-lock-keywords-case-fold-search) 't)
      (set (make-local-variable 'comment-start) ";")
      (set (make-local-variable 'comment-start) "#")
      (set (make-local-variable 'comment-end) "\n")
      (set (make-local-variable 'fill-column) '100);cause I was having problems with autofill.
      (set (make-local-variable 'auto-fill-mode) -1); I did this as I was having trouble with autofill. YMMV.
      (use-local-map remind-conf-mode-map)
      )

    (provide 'remind-conf-mode)
;;; remind-conf-mode.el ends here

;;; TODO or would like to do.
;;; completion for keywords and for inbuilt functions.
;;; Hook into the autocomplete library. 
;;; work out how to make the syntax highlighting work only before the (MSG|MSF)
;;; keywords and not after. 