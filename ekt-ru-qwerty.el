;;; ekt-ru-qwerty.el --- Keyboard translation (ru) for Emacs -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2023 Pavel Stepanov
;;
;; Author: Pavel Stepanov <paulkreuzmann@gmail.com>
;; Maintainer: Pavel Stepanov <paulkreuzmann@gmail.com>
;; Version: 0.0.1
;; Keywords: convenience i18n languages
;; Homepage: https://github.com/suess/ekt
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Russian qwerty-based translation for use with ekt.
;;
;;; Code:

(require 'ekt)

(defvar ekt-ru-qwerty/from ",ЮБЬТИМСЧЯ\\ЭЖДЛОРПАВЫФХЪЗЩШГНЕКУЦЙЁ+_)(*?:%;№\"!.юбьтимсчяэждлорпавыфъхзщшгнекуцйё/=-")
(defvar ekt-ru-qwerty/to "?><MNBVCXZ\\\":LKJHGFDSA}{POIUYTREWQ~+_)(*&^%$#@!/.,mnbvcxz';lkjhgfdsa][poiuytrewq`|=-")

(defun ekt-ru-qwerty/make-translation (layout-name)
  "Create russian `key-translation-map' for layout LAYOUT-NAME."
  (ekt/make-translation layout-name ekt-ru-qwerty/from ekt-ru-qwerty/to))

(provide 'ekt-ru-qwerty)
;;; ekt-ru-qwerty.el ends here
