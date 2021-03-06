;;; youdao-dictionary.el --- Youdao Dictionary interface for Emacs

;; Copyright © 2015 Chunyang Xu

;; Author: Chunyang Xu <xuchunyang56@gmail.com>
;; URL: https://github.com/xuchunyang/youdao-dictionary.el
;; Package-Requires: ((popup "0.5.0") (chinese-word-at-point "0.2") (names "0.5") (emacs "24"))
;; Version: 0.1
;; Created: 11 Jan 2015
;; Keywords: convenience, Chinese, dictionary

;; This program is free software; you can redistribute it and/or modify
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
;;
;; A simple Youdao Dictionary interface for Emacs
;;
;; Below are commands you can use:
;; `youdao-dictionary-search-at-point'
;; Search word at point and display result with buffer
;; `youdao-dictionary-search-at-point+'
;; Search word at point and display result with popup-tip
;; `youdao-dictionary-search-from-input'
;; Search word from input and display result with buffer
;; `youdao-dictionary-search-and-replace'
;; Search word at point and display result with popup-menu, replace word with
;; selected translation.

;;; Code:
(require 'json)
(require 'url)
;; (require 'chinese-word-at-point)
(require 'popup)
(require 'names)

;;;###autoload
(define-namespace youdao-dictionary-

(defconst api-url
  "http://fanyi.youdao.com/openapi.do?keyfrom=YouDaoCV&key=659600698&type=data&doctype=json&version=1.1&q=%s"
  "Youdao dictionary API template, URL `http://dict.youdao.com/'.")

(defconst buffer-name "*Youdao Dictionary*"
  "Buffer name.")

(defvar search-history-file (expand-file-name (concat user-emacs-directory
                                                      ".youdao-search-history"))
  "File for saving searching history.")

(defvar use-chinese-word-segmentation nil
  "Set to Non-nil for Chinese word segmentation(中文分词) support")

(defun -format-request-url (query-word)
  "Format QUERY-WORD as a HTTP request URL."
  (format api-url query-word))

(defun -request (word)
  "Request WORD, return JSON as an alist if successes."
  ;;(when (and search-history-file (file-writable-p search-history-file))
  ;; Save searching history
  ;;(append-to-file (concat word "\n") nil search-history-file))
  (let (json)
    (with-current-buffer (url-retrieve-synchronously
                          (-format-request-url word))
      (set-buffer-multibyte t)
      (goto-char (point-min))
      (when (not (string-match "200 OK" (buffer-string)))
        (error "Problem connecting to the server"))
      (re-search-forward "^$" nil 'move)
      (setq json (json-read-from-string
                  (buffer-substring-no-properties (point) (point-max))))
      (kill-buffer (current-buffer)))
    json))

(defun -explains (json)
  "Return explains as a vector extracted from JSON."
  (cdr (assoc 'explains (cdr (assoc 'basic json)))))

(defun -prompt-input ()
  "Prompt input object for translate."
  (let ((current-word (-region-or-word)))
    (read-string (format "Word (%s): "
                         (or current-word ""))
                 nil nil
                 current-word)))

(defun -strip-explain (explain)
  "Remove unneed info in EXPLAIN for replace.

i.e. `[语][计] dictionary' => 'dictionary'."
  (replace-regexp-in-string "^[[].* " "" explain))

(defun -region-or-word ()
  "Return word in region or word at point."
  (if (use-region-p)
      (buffer-substring-no-properties (region-beginning)
                                      (region-end))
    (thing-at-point (if use-chinese-word-segmentation
                        'chinese-or-other-word
                      'word)
                    t)))

(setq drill-word nil)
(setq drill-content nil)
(setq drill-phonetic nil)
(defvar youdao-drill-file nil)
(defun save-drill ()
  (interactive)
  (let ((buffer (find-file-noselect youdao-drill-file)))
    (with-current-buffer buffer
      (goto-char (point-min))
      (if (search-forward (concat "* " drill-word) nil t)
          (message (concat "'" drill-word "' alread drilled"))
        (progn
          (goto-char (point-max))
          (insert (format "* %s    :drill:\n{%s}\n** Answer\n%s" drill-word drill-phonetic drill-content))
          (save-buffer)
          )
        )
      )
    ))

(defun -format-result (word)
  "Format request result of WORD."
  (let* ((json (-request word))
         (query (cdr (assoc 'query json)))
         (phonetic (cdr (assoc 'phonetic (cdr (assoc 'basic json)))))
         (basic-explains (cdr (assoc 'explains (cdr (assoc 'basic
                                                           json)))))
         (basic-explains-str "")
         (web-references (cdr (assoc 'web json)))
         (web-references-str ""))
    (setq drill-word word)
    (mapc (lambda (explain) (setq basic-explains-str
                                  (concat basic-explains-str
                                          (format "- %s\n" explain))))
          basic-explains)
    (mapc (lambda (key-value)
            (let ((key (cdr (assoc 'key key-value)))
                  (values (cdr (assoc 'value key-value)))
                  (values-str ""))
              (setq web-references-str (concat web-references-str
                                               (format "- %s :: " key)))
              (mapc (lambda (value)
                      (setq values-str (concat values-str ", " value)))
                    values)
              (setq values-str (substring values-str 2))
              (setq web-references-str (concat web-references-str
                                               (format "%s\n" values-str)))))
          web-references)
    (setq drill-content (concat basic-explains-str "\n" web-references-str))
    (setq drill-phonetic phonetic)
    (if (and phonetic youdao-drill-file)
        (save-drill)
      )
    (format "%s [%s]\n\n* Basic Explains\n%s\n* Web References\n%s\n"
            query phonetic basic-explains-str web-references-str)))

(defun -search-and-show-in-buffer (word)
  "Search WORD and show result in `youdao-dictionary-buffer-name' buffer."
  (if word
      (progn 
        (sw/push-window-configuration)
        (with-current-buffer (get-buffer-create buffer-name)
          (setq buffer-read-only nil)
          (erase-buffer)
          (local-set-key (kbd "q") '(lambda()
                                      (interactive)
                                      (sw/pop-window-configuration)))
          ;; (when (featurep 'org)
          ;;   (org-mode))
          (insert (-format-result word))
          (goto-char (point-min))
          (setq buffer-read-only t)
          ;; (local-set-key "q" 'bury-buffer)
          (switch-to-buffer-other-window buffer-name)))
    (search-from-input)
    ))

:autoload
(defun search-at-point ()
  "Search word at point and display result with buffer."
  (interactive)
  (let ((word (-region-or-word)))
    (-search-and-show-in-buffer word)))

:autoload
(defun search-at-point+ ()
  "Search word at point and display result with popup-tip."
  (interactive)
  (let ((word (-region-or-word)))
    (if word
        (popup-tip (-format-result word))
      (search-from-input))))

:autoload
(defun search-from-input ()
  "Search word from input and display result with buffer."
  (interactive)
  (let ((word (-prompt-input)))
    (-search-and-show-in-buffer word)))

:autoload
(defun search-and-replace ()
  "Search word at point and replace this word with popup menu."
  (interactive)
  (if (use-region-p)
      (let ((region-beginning (region-beginning)) (region-end (region-end))
            (selected (popup-menu* (mapcar #'-strip-explain
                                           (append (-explains
                                                    (-request
                                                     (-region-or-word)))
                                                   nil)))))
        (when selected
          (insert selected)
          (kill-region region-beginning region-end)))
    ;; No active region
    (let* ((bounds (bounds-of-thing-at-point (if use-chinese-word-segmentation
                                                 'chinese-or-other-word
                                               'word)))
           (beginning-of-word (car bounds))
           (end-of-word (cdr bounds)))
      (when bounds
        (let ((selected
               (popup-menu* (mapcar
                             #'-strip-explain
                             (append (-explains
                                      (-request
                                       (thing-at-point
                                        (if use-chinese-word-segmentation
                                            'chinese-or-other-word
                                          'word))))
                                     nil)))))
          (when selected
            (insert selected)
            (kill-region beginning-of-word end-of-word)))))))

)

(provide 'youdao-dictionary)

;; Local Variables:
;; coding: utf-8
;; fill-column: 80
;; End:

;;; youdao-dictionary.el ends here
