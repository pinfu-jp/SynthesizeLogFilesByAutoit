#include <File.au3>
#include <Array.au3>
#include <Date.au3>
;~ #include <Regexp.au3>

Global Const $DEBUG_LOG_PATH = "debug.log"
Global Const $OUT_SYMBLE_PRE_WORD = "●"
Global Const $TIMESTAMP_PATTERN = "\d{4}[-./]\d{2}[-./]\d{2} \d{2}:\d{2}:\d{2}"

;~ Global $logger

Func Main()
    $logger = FileOpen($DEBUG_LOG_PATH, 2)

    Local $folder_path = "C:\example\folder"
    Local $output_file_path = "C:\example\output.csv"

    separate_timestamp_and_write_to_csv($folder_path, $output_file_path)
    
    FileClose($logger)
EndFunc


; 指定されたフォルダ内の全てのログファイルに対して、タイムスタンプとログ文字列を分離し、csvファイルに出力
Func separate_timestamp_and_write_to_csv($folder_path, $output_file_path)
    ConsoleWrite("separate_timestamp_and_write_to_csv() 開始")

    Local $out_lines = []
    For $file_name In _FileListToArray($folder_path)
        Local $file_path = $folder_path & "\" & $file_name
        separate_timestamp_by_files($out_lines, $file_path)
    Next

	; タイムスタンプでソート 0番目は件数を示しているので注意
    _ArraySort($out_lines, 0, 1)

	; csv出力
    Local $f = FileOpen($output_file_path, 2)

	;~ ヘッダー
	Local $header_str = "タイムスタンプ" & ", " & "ログファイル" & ", " & "ログ内容" & "," 
    FileWriteLine($f, $header_str)

    For $line In $out_lines
		ReDim $line[3]
		Local $date_str = text_by_date_obj($line[0])
		Local $line_str = $date_str & ", " & $line[1] & ", " & $line[2] & "," 
        FileWriteLine($f, $line_str)
    Next
    FileClose($f)

    ConsoleWrite("separate_timestamp_and_write_to_csv() 正常終了")
EndFunc


;  ファイルからタイムスタンプと文字列を抽出
Func separate_timestamp_by_files(ByRef $out_lines, $file_path)

	ConsoleWrite("separate_timestamp_by_files() 開始 file:" & $file_path)

	Local $file_name = FileGetShortName($file_path)
	If StringInStr($file_name, $OUT_SYMBLE_PRE_WORD) Then
		ConsoleWrite("シンボル付きは対象外ファイル file:" & $file_path)
		Return
	EndIf

	If StringInStr($file_name, $DEBUG_LOG_PATH) Then
		ConsoleWrite("開発用ログは対象外ファイル file:" & $file_path)
		Return
	EndIf

	If Not StringRight($file_path, 4) == ".log" And Not StringRight($file_path, 4) == ".txt" Then
		ConsoleWrite("対象外ファイル file:" & $file_path)
		Return
	EndIf

	ConsoleWrite("対象ファイル file:" & $file_path)
	Local $hFile = FileOpen($file_path, 0)
	If @error Then
		ConsoleWrite("FileOpen error:" & @error)
		Return
	EndIf

	Local $line
	While 1
		$line = FileReadLine($hFile)
		If @error Then
			ExitLoop
		EndIf
		Local $separated = separate_timestamp($line)

		If $separated[0] == 2 Then
			Local $add_line_count = $out_lines[0] + 1
			ReDim $out_lines[$add_line_count][3]
			;~ タイムスタンプ, ファイル名, ログ文字列
			$out_lines[$add_line_count][0] = $separated[1]
			$out_lines[$add_line_count][1] = $file_name		
			$out_lines[$add_line_count][2] = $separated[2]
			$out_lines[0] = $add_line_count
		EndIf
	WEnd
	FileClose($hFile)

EndFunc


; 入力されたログ文字列からタイムスタンプとログ文字列を分離し、配列に格納する
Func separate_timestamp($log_line)

	Local $array[3]
	$match = StringRegExp($log_line, $timestamp_pattern, 0)
	If Not @error Then
		$timestamp_str = $match[0][0]
		$log_string = StringReplace($log_line, $timestamp_str, "")

        ; 日時型
        Local $date_obj = date_obj_by_text($timestamp_str)

        ConsoleWrite("[debug] date_obj:" & $date_obj & ", log_string:" & $log_string & @CRLF)
		$array[0] = 2
		$array[1]  = $date_obj
		$array[2]  = $log_string
    Else
		$array[0] = 0
    EndIf
        
	Return $array
EndFunc

; 文字列から日時型に変換する
Func date_obj_by_text($timestamp_str)
	$timestamp = StringSplit($timestamp_str, " ")
	$date = StringSplit($timestamp[0], "-")
	$time = StringSplit($timestamp[1], ":")

	;~ TODO: 2桁西暦や、時刻なしに対応したい

	Local $date_str = $timestamp_str
	Local $dateObj = _DateAdd("s", _DateDiff("s", "1970-01-01 00:00:00", $date_str), "1970-01-01 00:00:00")

	Return $dateObj
EndFunc

Func text_by_date_obj($date_obj)
	return _DateTimeFormat($date_obj, 1)
EndFunc