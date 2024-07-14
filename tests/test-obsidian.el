;;; test-obsidian.el --- Obsidian Tests -*- coding: utf-8; lexical-binding: t; -*-
(require 'obsidian)
(require 'buttercup)

(defvar obsidian--test-dir "./tests/test_vault")
(defvar obsidian--test--original-dir (or obsidian-directory obsidian--test-dir))
(defvar obsidian--test-number-of-tags 9)
(defvar obsidian--test-number-of-visible-tags 6)
(defvar obsidian--test-number-of-notes 11)
(defvar obsidian--test-number-of-visible-notes 9)
(defvar obsidian--test-number-of-visible-directories 2)
(defvar obsidian--test-visibility-cfg obsidian-include-hidden-files)

(describe "check path setting"
  (before-all (obsidian-specify-path obsidian--test-dir))
  (after-all (obsidian-specify-path obsidian--test--original-dir))

  (it "set to current"
    (expect obsidian-directory :to-equal (expand-file-name obsidian--test-dir))
    (expect (obsidian-specify-path ".") :to-equal (expand-file-name "."))))

(describe "obsidian-file-p"
  (before-all (obsidian-specify-path obsidian--test-dir))
  (after-all (obsidian-specify-path obsidian--test--original-dir))

  (it "include files right in vault"
    (expect (obsidian-file-p "./tests/test_vault/1.md") :to-be t))
  (it "include files in subdirs"
    (expect (obsidian-file-p "./tests/test_vault/subdir/1-sub.md") :to-be t))
  (it "exclude files in trash"
    (expect (obsidian-file-p "./tests/test_vault/.trash/trash.md") :to-be nil)))

(describe "obsidian list all visible files"
   (before-all (progn
                 (obsidian-specify-path obsidian--test-dir)
                 (setq obsidian-include-hidden-files nil)
                 (obsidian-update)))
   (after-all (progn
                (obsidian-specify-path obsidian--test--original-dir)
                (setq obsidian-include-hidden-files obsidian--test-visibility-cfg)
                (obsidian-update)))

  (it "check visible file count"
    (expect (length (obsidian-list-all-files)) :to-equal obsidian--test-number-of-visible-notes)))

(describe "obsidian list all files including hidden files"
   (before-all (progn
                 (obsidian-specify-path obsidian--test-dir)
                 (setq obsidian-include-hidden-files t)
                 (obsidian-update)))
   (after-all (progn
                (obsidian-specify-path obsidian--test--original-dir)
                (setq obsidian-include-hidden-files obsidian--test-visibility-cfg)
                (obsidian-update)))

  (it "check all files count"
    (expect (length (obsidian-list-all-files)) :to-equal obsidian--test-number-of-notes)))

(describe "obsidian-list-all-directories"
   (before-all (progn
                 (obsidian-specify-path obsidian--test-dir)
                 (setq obsidian-include-hidden-files nil)
                 (obsidian-update)))
   (after-all (progn
                (obsidian-specify-path obsidian--test--original-dir)
                (setq obsidian-include-hidden-files obsidian--test-visibility-cfg)
                (obsidian-update)))

  (it "check directory count"
    (expect (length (obsidian-list-all-directories)) :to-equal obsidian--test-number-of-visible-directories)))

(describe "obsidian-find-tags"
  (before-all (obsidian-specify-path obsidian--test-dir))
  (after-all (obsidian-specify-path obsidian--test--original-dir))

  (it "find tags in string"
    (expect (length (obsidian-find-tags "#foo bar #spam #bar-spam #spam_bar #foo+spam #foo=bar not tags")) :to-equal 6)))

(describe "obsidian-list-visible-tags"
  (before-all (progn
                (obsidian-specify-path obsidian--test-dir)
                (setq obsidian-include-hidden-files nil)
                (obsidian-update)))
  (after-all (progn
               (obsidian-specify-path obsidian--test--original-dir)
               (setq obsidian-include-hidden-files obsidian--test-visibility-cfg)
               (obsidian-update)))

  (it "find all tags in the vault"
    (expect (length (obsidian-tags)) :to-equal obsidian--test-number-of-visible-tags)))

(describe "obsidian list all tags including hidden tags"
  (before-all (progn
                (obsidian-specify-path obsidian--test-dir)
                (setq obsidian-include-hidden-files t)
                (obsidian-update)))
  (after-all (progn
               (obsidian-specify-path obsidian--test--original-dir)
               (setq obsidian-include-hidden-files obsidian--test-visibility-cfg)
               (obsidian-update)))

  (it "find all tags in the vault"
    (expect (length (obsidian-tags)) :to-equal obsidian--test-number-of-tags)))

(describe "obsidian-update"
  (before-all (progn
		(obsidian-specify-path obsidian--test-dir)
		(obsidian-clear-cache)))
  (after-all (obsidian-specify-path obsidian--test--original-dir))

  (it "check that tags var is empty before update"
    (expect (obsidian-tags) :to-be nil))
  (it "check tags are filled out after update"
    (expect (progn
	      (obsidian-update)
	      (length (obsidian-tags))) :to-equal obsidian--test-number-of-tags)))


(defvar-local obsidian--test-correct-front-matter "---
aliases: [AI, Artificial Intelligence]
tags: [one, two, three]
key4:
- four
- five
- six
---
")
(defvar obsidian--test-incorret-front-matter--not-start-of-file (s-concat "# Header\n" obsidian--test-correct-front-matter))

(describe "obsidian-aliases"
  (before-all (progn
		(obsidian-specify-path obsidian--test-dir)
                (obsidian-update)
		(setq obsidian--tags-list nil)
                ))
  (after-all (progn
	       (obsidian-specify-path obsidian--test--original-dir)
	       (setq obsidian--tags-list obsidian--test--original-tags-list)
               ))

  (it "check that front-matter is found"
    (expect (gethash 'aliases (obsidian-find-yaml-front-matter obsidian--test-correct-front-matter))
	    :to-equal ["AI" "Artificial Intelligence"]))

  (it "check that front-matter is ignored if not at the top of file"
    (expect (obsidian-find-yaml-front-matter obsidian--test-incorret-front-matter--not-start-of-file)
	    :to-equal nil))

  (it "check that front-matter in vault is correct"
    (let ((alias-list (obsidian-aliases)))
      (expect (length alias-list) :to-equal 6)
      (expect (seq-contains-p alias-list "2") :to-equal t)
      (expect (seq-contains-p alias-list "2-sub-alias") :to-equal t)
      (expect (seq-contains-p alias-list "complex file name") :to-equal t)
      (expect (seq-contains-p alias-list "alias-one-off") :to-equal t)
      (expect (seq-contains-p alias-list "alias1") :to-equal t)
      (expect (seq-contains-p alias-list "alias2") :to-equal t))))

(describe "obsidian--link-p"
  (it "non link"
    (expect (obsidian--link-p "not link") :to-equal nil))

  (it "wiki link"
    (expect (obsidian--link-p "[[foo.md]]") :to-equal t)
    (expect (obsidian--link-p "[[foo]]") :to-equal t)
    (expect (obsidian--link-p "[[foo|annotated link]]") :to-equal t))

  (it "markdown link"
    (expect (obsidian--link-p "[foo](bar)") :to-equal t)
    (expect (obsidian--link-p "[foo](bar.md)") :to-equal t)))

(describe "obsidian--find-links-to-file"
  (before-all (obsidian-specify-path obsidian--test-dir))
  (after-all (obsidian-specify-path obsidian--test--original-dir))

  (it "1.md"
    (expect (obsidian--find-links-to-file "1.md") :to-equal '("2.md"))))

(describe "obsidian-move-file"
  (before-all (obsidian-specify-path obsidian--test-dir))
  (after-all (obsidian-specify-path obsidian--test--original-dir))

  (let* ((orig-file-name
          (expand-file-name (s-concat obsidian--test-dir "/subdir/aliases.md")))
         (moved-file-name
          (expand-file-name (s-concat obsidian--test-dir "/inbox/aliases.md"))))

    (it "obsidian--files-hash-cache is updated when a file is moved"
        ;; Open file and confirm that it is in the files cache
        (let* ((executing-kbd-macro t)
               (unread-command-events (listify-key-sequence "subdir/aliases.md\n")))
          (call-interactively #'obsidian-jump))
        (expect (obsidian-cached-file-p orig-file-name)  :to-equal t)
        (expect (obsidian-cached-file-p moved-file-name) :to-equal nil)

        ;; Move the file and confirm that new path is in cache and old path is not
        (let* ((make-backup-files nil)
               (executing-kbd-macro t)
               (unread-command-events (listify-key-sequence "inbox\n") ))
          (call-interactively #'obsidian-move-file))
        (expect (obsidian-cached-file-p orig-file-name)  :to-equal nil)
        (expect (obsidian-cached-file-p moved-file-name) :to-equal t)

        ;; Return file and confirm that the cache was again updated
        (let* ((make-backup-files nil)
               (executing-kbd-macro t)
               (unread-command-events (listify-key-sequence "subdir\n") ))
          (call-interactively #'obsidian-move-file))
        (expect (obsidian-cached-file-p orig-file-name)  :to-equal t)
        (expect (obsidian-cached-file-p moved-file-name) :to-equal nil))))

(provide 'test-obsidian)
