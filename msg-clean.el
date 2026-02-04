;;; msg-clean.el --- Keep messages buffer clean  -*- lexical-binding: t; -*-

;; Copyright (C) 2022-2026  Shen, Jen-Chieh
;; Created date 2022-02-17 16:16:50

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; URL: https://github.com/jcs-elpa/msg-clean
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

(defgroup msg-clean nil
  "Keep messages buffer clean."
  :prefix "msg-clean-"
  :group 'convenience
  :link '(url-link :tag "Repository" "https://github.com/jcs-elpa/msg-clean"))

(defcustom msg-clean-mute-commands
  nil
  "List of commands to mute completely."
  :type '(list symbol)
  :group 'msg-clean)

(defcustom msg-clean-echo-commands
  nil
  "List of commands to inhibit log to *Messages* buffer."
  :type '(list symbol)
  :group 'msg-clean)

(defcustom msg-clean-minor-mode nil
  "Echo/Mute to all minor-mode."
  :type '(choice (const :tag "Mute minor-mode enable/disable" mute)
                 (const :tag "Echo minor-mode enable/disable" echo)
                 (const :tag "Does nothing" nil))
  :group 'msg-clean)

;;
;; (@* "Util" )
;;

(defun msg-clean--ad-add (lst fnc)
  "Do `advice-add' for LST with FNC."
  (dolist (cmd lst) (advice-add cmd :around fnc)))

(defun msg-clean--ad-remove (lst fnc)
  "Do `advice-remove' for LST with FNC."
  (dolist (cmd lst) (advice-remove cmd fnc)))

(defun msg-clean--function-symbol (symbol)
  "Return function name by SYMBOL."
  (cl-case symbol
    (`mute #'msg-clean--mute)
    (`echo #'msg-clean--echo)))

;;
;; (@* "Util" )
;;

(defun msg-clean--re-enable-mode (modename)
  "Re-enable the MODENAME."
  (msgu-silent
    (funcall-interactively modename -1) (funcall-interactively modename 1)))

(defun msg-clean--re-enable-mode-if-was-enabled (modename)
  "Re-enable the MODENAME if was enabled."
  (when (boundp modename)
    (when (symbol-value modename) (msg-clean--re-enable-mode modename))
    (symbol-value modename)))

(defun msg-clean--listify (obj)
  "Turn OBJ to list."
  (if (listp obj) obj (list obj)))

;;
;; (@* "Core" )
;;

(defun msg-clean--apply (inter fnc &rest args)
  "Apply (FNC, ARGS); INTER non-nil call it interactively."
  (if inter
      (apply #'funcall-interactively (append (list fnc) args))
    (apply fnc args)))

(defun msg-clean--mute (fnc &rest args)
  "Mute any commands (FNC, ARGS)."
  (msgu-silent
    (let ((inter (called-interactively-p 'interactive)))
      (apply #'msg-clean--apply inter fnc args))))

(defun msg-clean--echo (fnc &rest args)
  "Mute any commands (FNC, ARGS)."
  (msgu-inhibit-log
    (let ((inter (called-interactively-p 'interactive)))
      (apply #'msg-clean--apply inter fnc args))))

(defun msg-clean--minor-mode-ad-add (&rest _)
  "Apply `advice-add' mute/echo to all minor-mode."
  (when-let* ((func (msg-clean--function-symbol msg-clean-minor-mode)))
    (msg-clean--ad-add minor-mode-list func)))

(defun msg-clean--minor-mode-ad-remove (&rest _)
  "Apply `advice-remove' mute/echo to all minor-mode."
  (when-let* ((func (msg-clean--function-symbol msg-clean-minor-mode)))
    (msg-clean--ad-remove minor-mode-list func)))

(defun msg-clean--enable ()
  "Enable function `msg-clean-mode'."
  (msg-clean--ad-add msg-clean-mute-commands #'msg-clean--mute)
  (msg-clean--ad-add msg-clean-echo-commands #'msg-clean--echo)
  (msg-clean--minor-mode-ad-add)
  (advice-add 'add-minor-mode :after #'msg-clean--minor-mode-ad-add))

(defun msg-clean--disable ()
  "Disable function `msg-clean-mode'."
  (msg-clean--ad-remove msg-clean-mute-commands #'msg-clean--mute)
  (msg-clean--ad-remove msg-clean-echo-commands #'msg-clean--echo)
  (advice-remove 'add-minor-mode #'msg-clean--minor-mode-ad-add)
  (msg-clean--minor-mode-ad-remove))

;;;###autoload
(define-minor-mode msg-clean-mode
  "Minor mode `msg-clean-mode'."
  :global t
  :require 'msg-clean-mode
  :group 'msg-clean
  (if msg-clean-mode (msg-clean--enable) (msg-clean--disable)))

;;
;; (@* "Users" )
;;

(defun msg-clean--add-commands (command lst)
  "Add COMMAND to LST."
  (let ((commands (msg-clean--listify command)))
    (nconc lst commands)
    (msg-clean--re-enable-mode-if-was-enabled #'msg-clean-mode)))

;;;###autoload
(defun msg-clean-add-echo-commands (command)
  "Add COMMAND to echo list."
  (msg-clean--add-commands command msg-clean-echo-commands))

;;;###autoload
(defun msg-clean-add-mute-commands (command)
  "Add COMMAND to mute list."
  (msg-clean--add-commands command msg-clean-mute-commands))

(provide 'msg-clean-mode)
;; Local Variables:
;; coding: utf-8
;; no-byte-compile: t
;; End:
;;; msg-clean.el ends here
