;;; ekt-ru.el --- Keyboard translation (ru) for Emacs -*- lexical-binding: t; -*-
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
;;  Russian translation for use with ekt.
;;
;;; Code:

(require 'ekt)

(defvar ekt-ru/en-chars "?><MNBVCXZ\\\":LKJHGFDSA}{POIUYTREWQ~+_)(*&^%$#@!/.,mnbvcxz';lkjhgfdsa][poiuytrewq`|=-")
(defvar ekt-ru/ru-chars ",ЮБЬТИМСЧЯ\\ЭЖДЛОРПАВЫФХЪЗЩШГНЕКУЦЙЁ+_)(*?:%;№\"!.юбьтимсчяэждлорпавыфъхзщшгнекуцйё/=-")
(ekt/make-translation "ru" ekt-ru/ru-chars ekt-ru/en-chars)

(provide 'ekt-ru)
;;; ekt-ru.el ends here
