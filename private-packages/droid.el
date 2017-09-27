(defun droid(&optional command)
  (interactive)
  (unless command
    (setq command (ido-completing-read "command: " '("make" "push" "sync" "all" "log" "reboot" "kill" ))))
  (cond
   ((string= command "make") (call-interactively 'droid-make))
   ((string= command "push") (call-interactively 'droid-push))
   ((string= command "sync") (call-interactively 'droid-sync))
   ((string= command "all") (call-interactively 'droid-all))
   ((string= command "log") (call-interactively 'droid-log))
   ((string= command "reboot") (call-interactively 'droid-reboot))
   ((string= command "kill") (call-interactively 'droid-kill))))

(defun droid-kill()
  (interactive)
  (let ((droid_process (start-process "droid-kill" nil "droid" "list_process")))
    (setq process_list nil)
    (set-process-filter droid_process '(lambda(process output)
					 (setq output (replace-in-string output "" ""))
					 (setq process_list (append process_list (split-string output)))))

    (set-process-sentinel droid_process '(lambda(proc change)
    					   (when (string-match "finished" change)
    					     (setq target (ido-completing-read "target: " process_list))
					     (when target
					       (start-process "nil" nil "droid" "kill" target)))))))

(defun droid-log ()
  (interactive)
  (let ((orig-command compile-command))
    (when (get-buffer "*droid-log*")
      (switch-to-buffer "*droid-log*")
      (return))
    (setq command "droid log")
    (with-current-buffer (compilation-start command nil)
      (rename-buffer "*droid-log*"))
    (switch-to-buffer-other-window "*droid-log*")
    (delete-other-windows)
    (setq compile-command orig-command)))

(defun droid-reboot()
  (interactive)
  (start-process "droid-reboot" nil "droid" "reboot"))

(defun droid-sync ()
  (interactive)
  (let ((orig-command compile-command))
    (if (get-buffer "*droid-sync*")
	(kill-buffer "*droid-sync*"))
    (setq command "droid sync")
    (with-current-buffer (compilation-start command nil)
      (rename-buffer "*droid-sync*"))
    (switch-to-buffer-other-window "*droid-sync*")
    (delete-other-windows)
    (setq compile-command orig-command)))

(defun droid-push ()
  (interactive)
  (let ((orig-command compile-command))
    (if (get-buffer "*droid-push*")
	(kill-buffer "*droid-push*"))

    ;; (setq args (read-from-minibuffer
    ;;     	(format (concat "droid push "))
    ;;     	"default" nil nil nil))
    ;; (setq command (concat "droid push " args))
    (setq command "droid push")
    (with-current-buffer (compilation-start command nil)
      (rename-buffer "*droid-push*")
      (pop-to-buffer (current-buffer)))
    ;; (switch-to-buffer-other-window "*droid-push*")
    ;; (delete-other-windows)
    (setq compile-command orig-command)))

(defun droid-make ()
  (interactive)
  (let ((orig-command compile-command))
    (if (get-buffer "*compilation*")
	(kill-buffer "*compilation*"))
    (setq command "droid make")
    (with-current-buffer (compilation-start command nil)
      (rename-buffer "*compilation*")
      (pop-to-buffer (current-buffer)))
    ;; (switch-to-buffer-other-window "*compilation*")
    ;; (delete-other-windows)
    (setq compile-command orig-command)))

(defun droid-all ()
  (interactive)
  (let ((orig-command compile-command))
    (if (get-buffer "*compilation*")
	(kill-buffer "*compilation*"))
    (setq command "droid all")
    (with-current-buffer (compilation-start command nil)
      (rename-buffer "*compilation*")
      (pop-to-buffer (current-buffer)))
    ;; (switch-to-buffer-other-window "*compilation*")
    ;; (delete-other-windows)
    (setq compile-command orig-command)))

(provide 'droid)
