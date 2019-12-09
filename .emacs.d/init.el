;; Set backspace to C-h
(global-set-key "\C-h" 'delete-backward-char)

;; When opened from Desktop entry, PATH won't be set to shell's value.
(let ((path-str
       (replace-regexp-in-string
        "\n+$" "" (shell-command-to-string "echo $PATH"))))
  (setenv "PATH" path-str)
  (setq exec-path (nconc (split-string path-str ":") exec-path)))

;; generic settings
(column-number-mode t)
(display-time)
(which-function-mode 1)
(setq inhibit-startup-message t)
(setq initial-scratch-message "")

;; set encoding
(set-language-environment 'Japanese)
(prefer-coding-system 'utf-8)

;; hide toolbar
(tool-bar-mode 0)

;; default to unified diffs
(setq diff-switches "-u")

(require 'uniquify)
(setq uniquify-buffer-name-style 'post-forward-angle-brackets)

(global-set-key "\C-x\C-i" 'indent-region)
(setq completion-ignore-case t)

(transient-mark-mode t)

;; define my macro
(fset 'copy-upper-row
   [up ?\C-  ?\C-e ?\M-w down ?\C-y])
(global-set-key "\C-cu" 'copy-upper-row)

(setq ediff-window-setup-function 'ediff-setup-windows-plain)

;;Auto indent at paragraph
(global-set-key "\C-m" 'newline-and-indent)

;; Delete an auto saved file at closing emacs.
(setq delete-auto-save-files t)

;; Type back slash character instead of Yen mark.
(define-key global-map [?¥] [?\\])

;; Don't create backup files.
(setq make-backup-files nil)

;; Ricky
(set-face-attribute 'default nil :family "Ricty Diminished" :height 150)
(set-fontset-font "fontset-default" 'japanese-jisx0208 '("Ricty Diminished" . "iso10646-*"))

;; Initial frame size
(setq initial-frame-alist
      (append (list
        '(width . 90)
        '(height . 50)
        )
        initial-frame-alist))
(setq default-frame-alist initial-frame-alist)

;; Set tab character as space
(setq-default tab-width 4 indent-tabs-mode nil)

;; Highlight spaces at line end
(when (boundp 'show-trailing-whitespace)
  (setq-default show-trailing-whitespace t))

;; Show line number
(global-linum-mode t)
(set-face-attribute `linum nil
                    :foreground "#800"
                    :height 0.9)

;; Invalid the global keybind of C-z
(global-unset-key "\C-z")
