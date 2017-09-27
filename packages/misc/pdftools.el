;;; pdftools.el --- a collection of pdf tools to mimic ps-spool- functions

;; Copyright (C) 2011 Peter H. Mao

;; Author: Peter H. Mao <peter.mao@gmail.com> <peterm@srl.caltech.edu>
;; Version %Id: 2%

;;; CHANGE LOG

;;; COMMENTARY: In a civilized world, you wouldn't need this, but the
;;; world is not civlized.

;;; SETUP: (load "pdftools")

;;; USAGE: All of the functions here use ps-spool- functions and then
;; call ps2pdf to generate the pdf file.  If no prefix arg is given,
;; the pdf file will be opened.  With a prefix, the file is saved but
;; not opened.
;;
;; If no filename is given, then the current buffer name is used, with
;; ".pdf" appended
;;
;; If the output is not to your liking, customize variables in the ps
;; group.

;;; CODE:

					;(defun pdf-debug (quiet filename)
					;  "debugger for pdftools"
					;  (interactive "P\nGFile name: ")
					;  (if (file-directory-p filename)
					;      (setq filename (concat (buffer-name) ".pdf")))
					;  (print filename)
					;)

(defun print-buffer-to-pdf (quiet filename)
  "Save buffer as a pdf file.
With prefix arg (C-u), display of output is suppressed.
'quiet' is set by the prefix argument
'filename' is interactively prompted"
  (interactive "P\nGFile name: ")
  (if (file-directory-p filename)
      (setq filename (concat (buffer-name) ".pdf")))
  (if (get-buffer "*PostScript*") (kill-buffer "*PostScript*"))
  (ps-spool-buffer)
  (set-buffer "*PostScript*")
  (shell-command-on-region 1 (point-max) 
                           (format "ps2pdf - %s" filename))
  (if (not quiet) (find-file filename))
  )

(defun print-buffer-to-pdf-with-faces (quiet filename)
  "Save buffer as a pdf file with faces.
With prefix arg (C-u), display of output is suppressed.
'quiet' is set by the prefix argument
'filename' is interactively prompted"
  (interactive "P\nGFile name: ")
  (if (file-directory-p filename)
      (setq filename (concat (buffer-name) ".pdf")))
  (if (get-buffer "*PostScript*") (kill-buffer "*PostScript*"))
  (ps-spool-buffer-with-faces)
  (set-buffer "*PostScript*")
  (shell-command-on-region 1 (point-max) 
                           (format "ps2pdf - %s" filename))
  (if (not quiet) (find-file filename))
  )

(defun print-region-to-pdf (quiet filename start end)
  "Save region as a pdf file.
With prefix arg (C-u), display of output is suppressed.
'quiet' is set by the prefix argument
'filename' is interactively prompted"
  (interactive "P\nGFile name: \nr")
  (if (file-directory-p filename)
      (setq filename (concat (buffer-name) ".pdf")))
  (if (get-buffer "*PostScript*") (kill-buffer "*PostScript*"))
  (ps-spool-region start end)
  (set-buffer "*PostScript*")
  (shell-command-on-region 1 (point-max)
                           (format "ps2pdf - %s" filename))
  (if (not quiet) (find-file filename))
  )

(defun print-region-to-pdf-with-faces (quiet filename start end)
  "Save region as a pdf file with faces.
With prefix arg (C-u), display of output is suppressed.
'quiet' is set by the prefix argument
'filename' is interactively prompted"
  (interactive "P\nGFile name: \nr")
  (if (file-directory-p filename)
      (setq filename (concat (buffer-name) ".pdf")))
  (if (get-buffer "*PostScript*") (kill-buffer "*PostScript*"))
  (ps-spool-region-with-faces start end)
  (set-buffer "*PostScript*")
  (shell-command-on-region 1 (point-max)
                           (format "ps2pdf - %s" filename))
  (if (not quiet) (find-file filename))
  )

(setq ps-multibyte-buffer 'bdf-font-except-latin)
;; sudo apt-get install emacs-intl-fonts
;; 在 ubuntu 里字体的位置不是默认的
;; /usr/local/share/emacs/fonts/bdf
;; 而是
;; /usr/share/emacs/fonts/bdf
(add-to-list 'bdf-directory-list "/usr/share/emacs/fonts/bdf")
(setq ps-paper-type 'a4       ;; default lettle
      ps-font-family 'Courier ;; default Courier
      ps-font-size 8.8        ;; default 8.5
      ps-print-header nil     ;; default t
      ps-header-lines 2       ;; default 2
      ps-landscape-mode nil)  ;; default nil

(provide 'pdftools)

;;; pdftools.el ends here
