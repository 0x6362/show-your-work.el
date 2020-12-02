;;; show-your-work.el ---  Simplify documenting code -*- lexical-binding: t -*-

;; Copyright (C) 2020 Cate B. <0x6362@users.noreply.github.com>

;; Author: Cate B. <0x6362@users.noreply.github.com>

;; URL: https://github.com/0x6362/reload-on-save
;; Package-Version: 20201106.0
;; Package-Requires: ((emacs "27.1"))
;; Version: 1.0

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.


;;; Commentary:
;;
;; A set of helpful functions for storing code blocks to be inserted into an org document.

;;; Code:

(require 'org-capture)
(require 'which-func)

(defun show-your-work--git-link-available-p ()
  "Check if git-link is available for use."
  (fboundp 'git-link))

(defun show-your-work--git-link-copy-url-only ()
  "Get a permalink via git-link if available."
  (if (show-your-work--git-link-available-p)
      (let (git-link-open-in-browser)
        (call-interactively 'git-link)
        (pop kill-ring))
    (error "Install git-link.el to use this functionality")))

(defun show-your-work--org-capture-get-src-block-string (mode)
  "Return org-src block string that will highlight for symbol MODE.

E.g. tuareg-mode will return 'ocaml', 'python-mode', 'python', etc..."

  (let ((mm (intern (replace-regexp-in-string "-mode" "" (format "%s" mode)))))
    (or (car (rassoc mm org-src-lang-modes)) (format "%s" mm))))

(defun show-your-work--yank-syntax-highlighted (start end)
  "Yank from START to END and highlight using Pygments.

If no region is selected, copy the whole buffer (or buffer contents if narrowed)"
  (interactive "r")
  (let* ((language (show-your-work--org-capture-get-src-block-string major-mode))
         (command (format "pygmentize -f rtf -O style=emacs,font=Inconsolata -l '%s' | pbcopy" language)))
    (if (equal start end)
        (setq start (point-min)
              end (point-max)))
    (shell-command-on-region start end command nil nil)))

;;;###autoload
(defun show-your-work-kill-snippet (arg)
  "Wrap region or defun at point in an org-src block and push onto kill ring.

With prefix ARG, uses 'git-link-copy-url-only' to "
  (interactive "p")
  (let (start end bounds
              (inhibit-message t))
    (if (use-region-p)
        (setq start (region-beginning) end (region-end))
      (progn
        (setq bounds (or (bounds-of-thing-at-point 'defun) (bounds-of-thing-at-point 'sentence)))
        (setq start (car bounds) end (cdr bounds))))

    (let* ((blk (buffer-substring-no-properties start end))
          (func-name (which-function))
          (file-name (or (buffer-file-name) (buffer-name)))
          (line-number (line-number-at-pos start))
          (remote-link-source (if arg (show-your-work--git-link-copy-url-only)))
          (local-file-link (format "file:%s::%s" file-name line-number))
          (link-to-file (org-link-make-string (or remote-link-source local-file-link) (format "%s:%d" (buffer-name) line-number)))
          (org-src-mode (show-your-work--org-capture-get-src-block-string major-mode)))
      (with-temp-buffer
        (org-mode)
        (insert (format
                 "%s // ~%s~
#+begin_src %s
%s
#+end_src"
                 link-to-file
                 func-name
                 org-src-mode
                 (string-trim blk)))
        (kill-ring-save (point-min) (point-max))))))

(provide 'show-your-work)
;;; show-your-work.el ends here
