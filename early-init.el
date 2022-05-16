;; Base variables
(defvar *emacsd-version* "0.0.2-SNAPSHOT")
(defvar *emacsd-start-time* (current-time))
(defvar *user-name* (getenv (if (equal system-type 'windows-nt) "USERNAME" "USER")))
(defvar *emacsd-system-name* (system-name))
(defvar *emacsd-dir*
  (file-name-directory (or load-file-name
                           (buffer-file-name))))

(message "Powering up version %s of your configuration, %s!" *emacsd-version* *user-name*)

(setq
 site-run-file nil                                                 ; No site-wide run-time initializations. 
 inhibit-default-init t                                         ; No site-wide default library
 gc-cons-threshold most-positive-fixnum    ; Very large threshold for garbage
 gc-cons-percentage 0.6															 ; collector during init
 package-enable-at-startup nil)                    ; We'll use straight.el

(setq native-comp-eln-load-path
      (list (expand-file-name ".eln-cache" user-emacs-directory)))

;; Reset garbage collector limit after init process has ended (32Mo)
(add-hook 'after-init-hook
          #'(lambda ()
							(setq
							 gc-cons-threshold (* 32 1024 1024)
							 gc-cons-percentage 0.1)))

(defun load-env-file (file)
  (if (null (file-exists-p file))
      (signal 'file-error (list "No env vars file exists " file ". Create one with the `env` command and store the output in"
				(concat *emacsd-dir* "env")))
    (when-let
        (env
         (with-temp-buffer
           (save-excursion
             (setq-local coding-system-for-read 'utf-8)
             (insert "\n")
             (insert-file-contents file))
           (save-match-data
             (when (re-search-forward "\n *\\([^#= \n]*\\)=" nil t)
               (setq
                env (split-string (buffer-substring (match-beginning 1) (point-max))
                                  "\n"
                                  'omit-nulls))))))
      (setq-default
       process-environment
       (append (nreverse env)
               (default-value 'process-environment))
       exec-path
       (append (split-string (getenv "PATH") path-separator t)
               (list exec-directory))
       shell-file-name
       (or (getenv "SHELL")
           (default-value 'shell-file-name)))
      env)))

(load-env-file (concat *emacsd-dir* "env"))

(require 'org)
(org-babel-tangle-file (concat *emacsd-dir* "init.org"))
