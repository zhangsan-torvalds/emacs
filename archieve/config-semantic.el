(semantic-mode 1)
(global-semantic-highlight-func-mode)
(global-semantic-highlight-edits-mode)
;; (global-semantic-idle-summary-mode)
;; (setq semantic-idle-summary-function (quote semantic-format-tag-summarize))
(global-set-key (kbd "C-c C-j") 'imenu)
(setq semantic-imenu-bucketize-file t)
(setq semantic-imenu-bucketize-type-members nil)
(setq semantic-imenu-buckets-to-submenu nil)
(setq semantic-imenu-expand-type-members nil)
(setq semantic-imenu-sort-bucket-function (quote semantic-sort-tags-by-type-increasing-ci))
(setq semantic-which-function-use-color t)
