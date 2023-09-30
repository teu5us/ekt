;;; ekt.el --- Keyboard translation for Emacs -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2023 Pavel Stepanov
;;
;; Author: Pavel Stepanov <paulkreuzmann@gmail.com>
;; Maintainer: Pavel Stepanov <paulkreuzmann@gmail.com>
;; Version: 0.0.1
;; Keywords: convenience i18n languages
;; Homepage: https://github.com/suess/ekt
;; Package-Requires: ((emacs "24.4"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Use Emacs and your keyboard layout with xkb-switch.
;;
;;  Note: you need xkb-switch to be available in PATH.
;;
;;  This package helps you build keymaps to substitute `key-translation-map'.
;;
;;  For defining translation maps see `ekt/make-translation'.
;;
;;  If you only use one keyboard layout beside US, you can just substitute
;;  `key-translation-map' yourselves.
;;
;;  Otherwise, try automated switching.  Emacs runs xkb-switch every second to
;;  check your active layout and activate the right translation map, which then
;;  translates key presses to bindings that Emacs knows.
;;
;;  To start automated key translation, run `ekt/start-layout-watcher'. To stop,
;;  execute `ekt/stop-layout-watcher'. Please note that there may be a delay
;;  before new `key-translation-map' activation.
;;
;;; Code:

(require 'cl-lib)
(require 'subr-x)

(defvar ekt/key-translation-map-timer nil
  "Store the timer that watches system keyboard layout and updates
`key-translation-map' accordingly.")

(defvar ekt/modifier-table (make-hash-table :test 'eq)
  "Table of modifiers used during translation.")

;; Populate the modifier table
(cl-loop for (mod str) in (cl-mapcar #'list
                                     '(super shift control meta hyper alt)
                                     (list "s-" "S-" "C-" "M-" "H-" "A-"))
         do (setf (gethash mod ekt/modifier-table) str))

;; modifier list to build key-translation-map objects
(defvar ekt/all-modifiers
  (append (hash-table-values ekt/modifier-table)
          (list "s-S-" "s-C-" "s-M-" "s-H-" "s-A-" "S-C-" "S-M-" "S-H-" "S-A-" "C-M-"
                "C-H-" "C-A-" "M-H-" "M-A-" "H-A-" "s-S-C-" "s-S-M-" "s-S-H-" "s-S-A-"
                "s-C-M-" "s-C-H-" "s-C-A-" "s-M-H-" "s-M-A-" "s-H-A-" "S-C-M-" "S-C-H-"
                "S-C-A-" "S-M-H-" "S-M-A-" "S-H-A-" "C-M-H-" "C-M-A-" "C-H-A-" "M-H-A-"
                "s-S-C-M-" "s-S-C-H-" "s-S-C-A-" "s-S-M-H-" "s-S-M-A-" "s-S-H-A-" "s-C-M-H-"
                "s-C-M-A-" "s-C-H-A-" "s-M-H-A-" "S-C-M-H-" "S-C-M-A-" "S-C-H-A-" "S-M-H-A-"
                "C-M-H-A-" "s-S-C-M-H-" "s-S-C-M-A-" "s-S-C-H-A-" "s-S-M-H-A-" "s-C-M-H-A-" "S-C-M-H-A-"))
  "List of modifiers to create translation maps.")

(defvar ekt/translation-maps (make-hash-table :test 'equal)
  "Maps for translation.")

(defvar ekt/key-translation-maps (make-hash-table :test 'equal)
  "Maps for `key-translation-map' substitution.")

;; Backup the original `key-translation-map'
(defvar ekt/us-key-translation-map (copy-keymap key-translation-map)
  "Backup the `key-translation-map' we have after launching Emacs.")
(setf (gethash "us" ekt/key-translation-maps) 'ekt/us-key-translation-map)

(defun ekt/get-lang ()
  "Get system keyboard layout."
  (string-trim (shell-command-to-string "xkb-switch")))

(defun ekt/update-key-translation-map ()
  "Substitute `key-translation-map'."
  (setq key-translation-map
        (symbol-value
         (gethash (ekt/get-lang) ekt/key-translation-maps))))

(defun ekt/stop-layout-watcher ()
  "Stop automatic `key-translation-map' substitution."
  (interactive)
  (and ekt/key-translation-map-timer
       (cancel-timer ekt/key-translation-map-timer)
       (setq ekt/key-translation-map-timer nil)))

;;;###autoload
(defun ekt/start-layout-watcher ()
  "Start automatic `key-translation-map' substitution."
  (interactive)
  (ekt/stop-layout-watcher)
  (setq ekt/key-translation-map-timer (run-with-timer 0 1 #'ekt/update-key-translation-map)))

(defun ekt/-split-translation-string (str)
  (split-string str "" t))

(defun ekt/-populate-with-modifiers (key-list)
  (cl-loop with result = key-list
           for m in ekt/all-modifiers
           do (setq result
                    (apply #'append result
                           (list
                            (mapcar #'(lambda (c)
                                        (concat m c))
                                    key-list))))
           finally (return result)))

(defun ekt/char-string-to-key-list (str)
  (ekt/-populate-with-modifiers
   (ekt/-split-translation-string str)))

(defun ekt/-make-key-translation-map (key-list)
  (let ((new-key-translation-map (copy-keymap ekt/us-key-translation-map)))
    (dolist (key key-list)
      (define-key new-key-translation-map (kbd key) #'ekt/translate-event))
    new-key-translation-map))

(defun ekt/-make-translation (from to)
  (let* ((keymap (make-sparse-keymap))
         (from-list (ekt/char-string-to-key-list from))
         (to-list (ekt/char-string-to-key-list to)))
    (cl-loop for (k v) in (cl-mapcar #'list from-list to-list)
             do (define-key keymap (kbd k) (kbd v))
             finally (return (list keymap
                                   (ekt/-make-key-translation-map from-list))))))

;;;###autoload
(defun ekt/make-translation (lang from to)
  "Create maps for translation and `key-translation-map' substitution, then
store their symbols in appropriate tables.

LANG is layout name as returned by xkb-switch
FROM is a string of characters to be translated
TO is a string of matching translation characters
FROM and TO must have the same length"
  (let ((translation-map-sym (intern (concat "ekt/" lang "-translation-map")))
        (key-translation-map-sym (intern (concat "ekt/" lang "-key-translation-map"))))
    (cl-destructuring-bind (translation keys)
        (ekt/-make-translation from to)
      (setf (symbol-value translation-map-sym) translation)
      (setf (symbol-value key-translation-map-sym) keys))
    (setf (gethash lang ekt/translation-maps) translation-map-sym)
    (setf (gethash lang ekt/key-translation-maps) key-translation-map-sym)))

(defvar ekt/*translate* t
  "Set to nil to avoid translation, see `ekt/read-key-wrapper'.")

(defun ekt/-translate-event (e map)
  "Internal translation magic."
  (let* ((-e (if (stringp e)
                 (string-to-char e)
               (aref e 0)))
         (modifiers (remove 'shift (event-modifiers -e))))
    (if (if (and (boundp 'evil-mode) evil-mode)
            (not (or (and (not modifiers) (evil-insert-state-p))
                     (and (not modifiers) (evil-emacs-state-p))
                     (and (not modifiers) (minibuffer-window-active-p (selected-window)))))
          modifiers)
        (lookup-key map e)
      e)))

(defun ekt/translate-event (prompt)
  "Translate the keyboard event that called this function. used in
`key-translation-map' substitution maps."
  (let* ((lang (ekt/get-lang))
         (map (symbol-value (gethash lang ekt/translation-maps)))
         (evec (this-single-command-keys))
         (e (vector (aref evec (- (length evec) 1)))))
    (if (string-equal "us" lang)
        e
      (if (and map ekt/*translate*)
          (ekt/-translate-event e map)
        e))))

(defun ekt/read-key-wrapper (f &rest args)
  "Advice function to avoid key translation where it is not required."
  (unwind-protect
      (progn
        (setq ekt/*translate* nil)
        (apply f args))
    (setq ekt/*translate* t)))

(advice-add 'read-key :around #'ekt/read-key-wrapper)
(when (boundp 'evil-mode)
  (advice-add 'evil-read-key :around #'ekt/read-key-wrapper))

(provide 'ekt)
;;; ekt.el ends here
