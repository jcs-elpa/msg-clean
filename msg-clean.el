;;; message-clean-mode.el --- Keep messages buffer clean  -*- lexical-binding: t; -*-

;; Copyright (C) 2022-2026  Shen, Jen-Chieh
;; Created date 2022-02-17 16:16:50

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; URL: https://github.com/jcs-elpa/message-clean-mode
;; Version: 0.1.0
;; Package-Requires: ((emacs "26.1") (msgu "0.1.0"))
;; Keywords: convenience messages clean

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Keep messages buffer clean.
;;

;;; Code:

(eval-when-compile
  (require 'msgu)
  (require 'cl-lib)
  (require 'subr-x))

(defgroup message-clean nil
  "Keep messages buffer clean."
  :prefix "message-clean-mode-"
  :group 'convenience
  :link '(url-link :tag "Repository" "https://github.com/jcs-elpa/message-clean-mode"))

(defcustom message-clean-mode-mute-commands
  nil
  "List of commands to mute completely."
  :type '(list symbol)
  :group 'message-clean)

(defcustom message-clean-mode-echo-commands
  nil
  "List of commands to inhibit log to *Messages* buffer."
  :type '(list symbol)
  :group 'message-clean)

(defcustom message-clean-mode-minor-mode nil
  "Echo/Mute to all minor-mode."
  :type '(choice (const :tag "Mute minor-mode enable/disable" mute)
                 (const :tag "Echo minor-mode enable/disable" echo)
                 (const :tag "Does nothing" nil))
  :group 'message-clean)

;;
;; (@* "Util" )
;;

(defun message-clean-mode--ad-add (lst fnc)
  "Do `advice-add' for LST with FNC."
  (dolist (cmd lst) (advice-add cmd :around fnc)))

(defun message-clean-mode--ad-remove (lst fnc)
  "Do `advice-remove' for LST with FNC."
  (dolist (cmd lst) (advice-remove cmd fnc)))

(defun message-clean-mode--function-symbol (symbol)
  "Return function name by SYMBOL."
  (cl-case symbol
    (`mute #'message-clean-mode--mute)
    (`echo #'message-clean-mode--echo)))

;;
;; (@* "Util" )
;;

(defun message-clean-mode--re-enable-mode (modename)
  "Re-enable the MODENAME."
  (msgu-silent
    (funcall-interactively modename -1) (funcall-interactively modename 1)))

(defun message-clean-mode--re-enable-mode-if-was-enabled (modename)
  "Re-enable the MODENAME if was enabled."
  (when (boundp modename)
    (when (symbol-value modename) (message-clean-mode--re-enable-mode modename))
    (symbol-value modename)))

(defun message-clean-mode--listify (obj)
  "Turn OBJ to list."
  (if (listp obj) obj (list obj)))

;;
;; (@* "Core" )
;;

(defun message-clean-mode--apply (inter fnc &rest args)
  "Apply (FNC, ARGS); INTER non-nil call it interactively."
  (if inter
      (apply #'funcall-interactively (append (list fnc) args))
    (apply fnc args)))

(defun message-clean-mode--mute (fnc &rest args)
  "Mute any commands (FNC, ARGS)."
  (msgu-silent
    (let ((inter (called-interactively-p 'interactive)))
      (apply #'message-clean-mode--apply inter fnc args))))

(defun message-clean-mode--echo (fnc &rest args)
  "Mute any commands (FNC, ARGS)."
  (msgu-inhibit-log
    (let ((inter (called-interactively-p 'interactive)))
      (apply #'message-clean-mode--apply inter fnc args))))

(defun message-clean-mode--minor-mode-ad-add (&rest _)
  "Apply `advice-add' mute/echo to all minor-mode."
  (when-let* ((func (message-clean-mode--function-symbol message-clean-mode-minor-mode)))
    (message-clean-mode--ad-add minor-mode-list func)))

(defun message-clean-mode--minor-mode-ad-remove (&rest _)
  "Apply `advice-remove' mute/echo to all minor-mode."
  (when-let* ((func (message-clean-mode--function-symbol message-clean-mode-minor-mode)))
    (message-clean-mode--ad-remove minor-mode-list func)))

(defun message-clean-mode--enable ()
  "Enable function `message-clean-mode'."
  (message-clean-mode--ad-add message-clean-mode-mute-commands #'message-clean-mode--mute)
  (message-clean-mode--ad-add message-clean-mode-echo-commands #'message-clean-mode--echo)
  (message-clean-mode--minor-mode-ad-add)
  (advice-add 'add-minor-mode :after #'message-clean-mode--minor-mode-ad-add))

(defun message-clean-mode--disable ()
  "Disable function `message-clean-mode'."
  (message-clean-mode--ad-remove message-clean-mode-mute-commands #'message-clean-mode--mute)
  (message-clean-mode--ad-remove message-clean-mode-echo-commands #'message-clean-mode--echo)
  (advice-remove 'add-minor-mode #'message-clean-mode--minor-mode-ad-add)
  (message-clean-mode--minor-mode-ad-remove))

;;;###autoload
(define-minor-mode message-clean-mode
  "Minor mode `message-clean-mode'."
  :global t
  :require 'message-clean-mode
  :group 'message-clean
  (if message-clean-mode (message-clean-mode--enable) (message-clean-mode--disable)))

;;
;; (@* "Users" )
;;

(defun message-clean-mode--add-commands (command lst)
  "Add COMMAND to LST."
  (let ((commands (message-clean-mode--listify command)))
    (nconc lst commands)
    (message-clean-mode--re-enable-mode-if-was-enabled #'message-clean-mode)))

;;;###autoload
(defun message-clean-mode-add-echo-commands (command)
  "Add COMMAND to echo list."
  (message-clean-mode--add-commands command message-clean-mode-echo-commands))

;;;###autoload
(defun message-clean-mode-add-mute-commands (command)
  "Add COMMAND to mute list."
  (message-clean-mode--add-commands command message-clean-mode-mute-commands))

(provide 'message-clean-mode)
;; Local Variables:
;; coding: utf-8
;; no-byte-compile: t
;; End:
;;; message-clean-mode.el ends here
