#lang racket

; Using SQL over sqlite seems the obvious way, but
; it might be also interesting to use functional patterns and composition, like "wordcount = compose(frequencies, partial(map, stem), str.split)"
; zip -> for/list
; foldl, for/fold
; filter, for/list
; cond -> match
; partial ->  compose + curry

; (require racket/string)
; for list-index
(require srfi/1)
(require racket/trace)
(require db)
(require racket/date)


; useful stats:
; - distribution of cores (or RAM) per user (or program) along time

; atop -r /var/log/atop/atop_20150507 -PPRG

;       PRM 	 Subsequent  fields:  PID,  name (between brackets), state, page size for this machine (in bytes), virtual memory size (Kbytes), resident memory size (Kbytes), shared text
;                memory size (Kbytes), virtual memory growth (Kbytes), resident memory growth (Kbytes), number of minor page faults, and number of major page faults.

;       PRD 	 Subsequent fields: PID, name (between brackets), state, kernel-patch installed ('y' or 'n'), standard io statistics used ('y' or 'n'), number of reads on disk, cumulative
;                number of sectors read, number of writes on disk, cumulative number of sectors written, and cancelled number of written sectors.

;       PRN 	 Subsequent  fields:  PID, name (between brackets), state, kernel-patch installed ('y' or 'n'), number of TCP-packets transmitted, cumulative size of TCP-packets transmit-
;                ted, number of TCP-packets received, cumulative size of TCP-packets received, number of UDP-packets transmitted, cumulative size of  UDP-packets  transmitted,  number  of
;                UDP-packets received, cumulative size of UDP-packets transmitted, number of raw packets transmitted, and number of raw packets received.

;       PRC 	 1 Host, 2 epoch, 3 Date , 4 Time, 5, 6 PID, 7 (program name), 8 state, 9 total number of clock-ticks per second for this machine, 10 CPU-consumption user mode  (clockticks),
;		 11  CPU-consumption in system mode (clockticks), 12 nice value, 13 priority, 14 realtime priority, 15 scheduling policy, 16 current CPU #, 17 sleep average.
; typically, kernel processes have PID < 1024
(define prcPattern
	;        1      2    3     4     5     6         7       8   9    10     11     12    13     14   15  16   17 
        #px"PRC \\w+ (\\d+) [^ ]+ [^ ]+ \\d+ (\\d+) \\((\\w+)\\) . \\d+ (\\d+) (\\d+) (\\d+) (\\d+) \\d+ \\d+ (\\d+) \\d+")

(define prcFieldNames
        '(Epoch Pid Program UserTicks SystemTicks Nice Priority Cpu))

;       PRG      1 Host, 2 epoch, 3 Date , 4 Time, 5, 6 PID, 7 (program name), 8 state, 9 real uid, 10 real gid, 11 TGID (same as PID), 12 total number of threads,
;		 13 exit code, 14 start time (epoch), 15 (full command  line)
;                16  PPID, 17 number of threads in state 'running' (R), 18 number of threads in state 'interruptible sleeping' (S), 19 number of threads in state 'uninterruptible
;                sleeping' (D), effective uid, effective gid, saved uid, saved gid, filesystem uid, filesystem gid, and elapsed time (hertz).
(define prgPattern
	;         1     2    3     4    5       6        7       8   9    10   11    12    13     14      15    16    17
        #px"PRG \\w+ (\\d+) [^ ]+ [^ ]+ \\d+ (\\d+) \\((\\w+)\\) . (\\d+) \\d+ \\d+ (\\d+) [^ ]+ \\d+ \\(.*\\) \\d+ (\\d+)")

(define prgFieldNames
        '(Epoch Pid Program Uid TotalThreads RunningThreads))

; atopsar (cpu)  1 HH:MM:SS, 2 CPU #, 3 %USR, 4 %nice, 5 %sys, 11 %idle
(define sarPattern
	;            1           2    3     4    5       6    7    8    9    10    11   
	; between fields there might be 1 or more spaces (hence all these "+")...
        #px"(\\d+):(\\d+):(\\d+) +all +(\\d+) +\\d+ +(\\d+) +\\d+ +\\d+ +\\d+ +\\d+ +\\d+ +(\\d+)")

(define sarFieldNames
        '(Hour Minute Second User System Idle))


(define (parse-line Pattern Line)
        (if (eof-object? Line) eof
              (let ((Match (regexp-match Pattern Line )))
	      	   (if (eq? Match #f)
		       null
		       (cdr Match)))))

(define (get-field FieldNames Fields FieldName)
        (let 
             ((FieldIndex (list-index (curry equal? FieldName) FieldNames)))
             (if (and (list? Fields) (<= FieldIndex (length Fields)))
                   (list-ref Fields FieldIndex)
                   null
                     ))) 

(define (field-accesor FieldNames)
	(curry get-field FieldNames))

(define (get-number-field GetField Fields FieldName)
	(if (or (null? Fields) (null? FieldName)) null
		(string->number (GetField Fields FieldName))))

(define (all? Conditions Values)
	(if (null? Conditions) #t
		(and (andmap (car Conditions) Values)
		     (all? (cdr Conditions) Values))))

(define (any? Conditions Values)
	(if (null? Conditions) #f
		(or (ormap (car Conditions) Values)
		     (any? (cdr Conditions) Values))))


;(define (exclude? Fields Tests)
;	(andmap

(define (cons-not-null Head List)
	(if (null? Head) List
	    (cons Head List)))

(define (parse-stdin Pattern Fields LineNumber)
	(when (= (modulo LineNumber 1000) 0) (printf "."))
        (let ((Line (read-line)))
	     ;  (printf "~a\n" Line)
             (cond
                ((eof-object? Line) (printf "\n" ) Fields)
;		((exclude? Fields Tests) (parse-stdin Pattern Fields (+ LineNumber 1)))
                (#t (parse-stdin Pattern (cons-not-null (parse-line Pattern Line) Fields) (+ LineNumber 1))))))



(define (prg-accum-by-epoch FieldAccessor Rows Field CurrentEpoch Accum Result)
	(cond
		((null? Rows) (cons (list CurrentEpoch Accum) Result))
		((= CurrentEpoch (get-number-field FieldAccessor (car Rows) 'Epoch))
		    (prg-accum-by-epoch FieldAccessor (cdr Rows) Field CurrentEpoch (+ Accum (get-number-field FieldAccessor (car Rows) Field)) Result))
		(#t (prg-accum-by-epoch FieldAccessor (cdr Rows) Field (get-number-field FieldAccessor (car Rows) 'Epoch) 0 (cons (list CurrentEpoch Accum) Result))) ))



(define db-name "atop-stats.sqlite")

(define DbConn null)

(define (create-db)
	(unless (file-exists? db-name)
		(printf "Creating database ~a...\n" db-name)
		(set! DbConn (sqlite3-connect #:database db-name #:mode 'create))
		(query-exec DbConn "create table prg (epoch integer, pid integer, uid integer, threads integer, primary key(epoch, pid));")
		(query-exec DbConn "create table prc (epoch integer, pid integer, program text, userticks integer, systemticks integer, primary key(epoch, pid));")
))

(define (insert-prg Fields)
	(query-exec DbConn "insert into prg values ($1, $2, $3, $4);" (get-field Fields 'Epoch) (get-field Fields 'Pid) (get-field Fields 'Uid) (get-field Fields 'Threads) ))

(define (insert-prc Fields)
	(query-exec DbConn "insert into prc values ($1, $2, $3, $4, $5);" (get-field Fields 'Epoch) (get-field Fields 'Pid) (get-field Fields 'Program) (get-field Fields 'UserTicks) (get-field Fields 'SystemTicks) ))

(define (filter-by Rows FieldAccessor Field Value)
	(filter (lambda (Fields) (= (get-number-field FieldAccessor Fields Field) Value))
		Rows))



; (trace parse-line)
; (trace any?)
; (trace prg-accum-by-epoch)
; (trace get-number-field)
; (trace filter-by)

; (all? (list positive? even?) '(2 4 6 8))
; (all? (list positive? odd?) '(2 4 6 8))
; (any? (list positive? even?) '(2 4 6 8))
; (any? (list positive? odd?) '(2 4 6 8))
; (any? (list negative? odd?) '(2 4 6 8))
; (any? (list negative? even?) '(2 4 6 8))


; coss melero joton vahid jvargas scipion web instruct
(define uid-list '(7204 7242 7245 7250 7265 7271 7273 7275))

; gnu-plot ouput: epoch threads-uid1 threads-uid2 ...

(define (accum-by-epoch-uid Rows Uid)
	(map (lambda (Accum) (list (car Accum) Uid (cadr Accum))) 
	     (prg-accum-by-epoch (field-accesor prgFieldNames) (filter-by Rows (field-accesor prgFieldNames) 'Uid Uid) 'RunningThreads 0 0 null)))

(define (stats Rows)
	(sort (apply append	
	       (map 
	       	    (curry accum-by-epoch-uid Rows)
	    	     uid-list))
	       #:key car <))

(define (print-report Stats Uids)
	(cond
		((null? Stats) null)
		((null? Uids) (printf "\n") (print-report Stats uid-list))
		((= (car Uids) (cadr (car Stats)))
		    (when (eq? Uids uid-list) (printf "~a " (car (car Stats)))) 
		    (printf "~a " (third (car Stats)))
		    (print-report (cdr Stats) (cdr Uids)))	       
		(#t (when (eq? Uids uid-list) (printf "~a " (car (car Stats)))) 
		    (printf "~a " 0) 
		    (print-report Stats (cdr Uids))) ))
		    
(define (time-to-epoch Row Year Month Day)
	(let ((FieldAccessor (field-accesor sarFieldNames)))
		(find-seconds (get-number-field FieldAccessor Row 'Second) (get-number-field FieldAccessor Row 'Minute) (get-number-field FieldAccessor Row 'Hour) Day Month Year)))


(time-to-epoch (car (parse-stdin sarPattern null 0))
	       2015 05 20)

(exit)

(print-report (stats (parse-stdin prgPattern null 0)) uid-list)

(create-db)

(when (null? DbConn) (set! DbConn (sqlite3-connect #:database db-name)))

; (map (lambda (Fields) (insert-prc Fields))
;	(parse-stdin null 0))

; Plotting
; set terminal png size 400,300 enhanced font "Helvetica,20"
; set output 'output.png'
; set xdata time
; set timefmt "%s"
; set xrange [1430949601-946684800:1431036001-946684800]
; set format x "%D %H:%M"
; set title "scipionweb@asimov"
; set ylabel "cores"
; plot "./atop_" using 1:2 title ""