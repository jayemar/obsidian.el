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

(describe "obsidian--file-p"
  (before-all (obsidian-specify-path obsidian--test-dir))
  (after-all (obsidian-specify-path obsidian--test--original-dir))

  (it "include files right in vault"
    (expect (obsidian--file-p "./tests/test_vault/1.md") :to-be t))
  (it "include files in subdirs"
    (expect (obsidian--file-p "./tests/test_vault/subdir/1-sub.md") :to-be t))
  (it "exclude files in trash"
    (expect (obsidian--file-p "./tests/test_vault/.trash/trash.md") :to-be nil)))

(describe "obsidian list all visible files"
   (before-all (progn
                 (obsidian-specify-path obsidian--test-dir)
                 (setq obsidian-include-hidden-files nil)
                 (obsidian-populate-cache)))
   (after-all (progn
                (obsidian-specify-path obsidian--test--original-dir)
                (setq obsidian-include-hidden-files obsidian--test-visibility-cfg)))

  (it "check visible file count"
    (expect (length (obsidian-files)) :to-equal obsidian--test-number-of-visible-notes)))

(describe "obsidian list all files including hidden files"
   (before-all (progn
                 (obsidian-specify-path obsidian--test-dir)
                 (setq obsidian-include-hidden-files t)
                 (obsidian-populate-cache)))
   (after-all (progn
                (obsidian-specify-path obsidian--test--original-dir)
                (setq obsidian-include-hidden-files obsidian--test-visibility-cfg)))

  (it "check all files count"
    (expect (length (obsidian-files)) :to-equal obsidian--test-number-of-notes)))

(describe "obsidian-directories"
   (before-all (progn
                 (obsidian-specify-path obsidian--test-dir)
                 (setq obsidian-include-hidden-files nil)
                 (obsidian-populate-cache)))
   (after-all (progn
                (obsidian-specify-path obsidian--test--original-dir)
                (setq obsidian-include-hidden-files obsidian--test-visibility-cfg)))

  (it "check directory count"
    (expect (length (obsidian-directories)) :to-equal obsidian--test-number-of-visible-directories)))

(describe "obsidian--find-tags-in-string"
  (before-all (obsidian-specify-path obsidian--test-dir))
  (after-all (obsidian-specify-path obsidian--test--original-dir))

  (it "find tags in string"
    (expect (length (obsidian--find-tags-in-string
                     "#foo bar #spam #bar-spam #spam_bar #foo+spam #foo=bar not tags #123 #+invalidtag"))
            :to-equal 6)))

(describe "obsidian-list-visible-tags"
  (before-all (progn
                (obsidian-specify-path obsidian--test-dir)
                (setq obsidian-include-hidden-files nil)
                (obsidian-populate-cache)))
  (after-all (progn
               (obsidian-specify-path obsidian--test--original-dir)
               (setq obsidian-include-hidden-files obsidian--test-visibility-cfg)))

  (it "find all tags in the vault"
    (expect (length (obsidian-tags)) :to-equal obsidian--test-number-of-visible-tags)))

(describe "obsidian list all tags including hidden tags"
  (before-all (progn
                (obsidian-specify-path obsidian--test-dir)
                (setq obsidian-include-hidden-files t)
                (obsidian-populate-cache)))
  (after-all (progn
               (obsidian-specify-path obsidian--test--original-dir)
               (setq obsidian-include-hidden-files obsidian--test-visibility-cfg)))

  (it "find all tags in the vault"
    (expect (length (obsidian-tags)) :to-equal obsidian--test-number-of-tags)))

(describe "obsidian-populate-cache"
  (before-all (progn
		(obsidian-specify-path obsidian--test-dir)
		(obsidian-clear-cache)))
  (after-all (obsidian-specify-path obsidian--test--original-dir))

  (it "check that tags var is empty before populate-cache"
    (expect (obsidian-tags) :to-be nil))
  (it "check tags are filled out after populate-cache"
    (expect (progn
	      (obsidian-populate-cache)
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
(defvar obsidian--test-incorrect-front-matter--not-start-of-file (s-concat "# Header\n" obsidian--test-correct-front-matter))

(describe "obsidian-aliases"
  (before-all (progn
		(obsidian-specify-path obsidian--test-dir)
                (obsidian-populate-cache)))
  (after-all (progn
	       (obsidian-specify-path obsidian--test--original-dir)))

  (it "check that front-matter is found"
    (expect (->> obsidian--test-correct-front-matter
                 obsidian--find-yaml-front-matter-in-string
                 (gethash 'aliases)) :to-equal ["AI" "Artificial Intelligence"]))

  (it "check that front-matter is ignored if not at the top of file"
    (expect (->> obsidian--test-incorrect-front-matter--not-start-of-file
                 obsidian--find-yaml-front-matter-in-string) :to-equal nil))

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
    (let* ((linkmap (obsidian-file-links "1.md"))
           (file1 (car (hash-table-keys linkmap))))
      (expect (length (hash-table-keys linkmap)) :to-equal 1)
      (expect (file-name-nondirectory file1) :to-equal "2.md"))))

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
