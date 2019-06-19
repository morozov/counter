            org $FC13

            JP START

; #FC16-#FC19 - STR$ значений
; счетчика (единицы...тысячи).

            DEFB $48,$48,$48,$48

; флаг запрета/разрешения включения счетчика.

ENABLED:    DEFB $00

; #FC1B-#FC1C - адрес счетчика в
; таблице.
            DEFW $0000

; #FC1D-#FC20 - адрес счетчика в
; дисплейном файле.

            DEFW $0000
            DEFW $0000

; #FC21-#FC31 - хэдер.

            DEFS $11

; #FC32-#FC89 - шаблоны цифр счетчика
; (стандартно, по 8 байт на символ);
; всего - 11 цифр, следующих:
; 0-1-2-3-4-5-6-7-8-9-0.

            DEFB $FE,$C6,$BA,$BA,$BA,$BA,$C6,$FE
            DEFB $FE,$EE,$CE,$EE,$EE,$EE,$82,$FE
            DEFB $FE,$C6,$BA,$F6,$EE,$DE,$82,$FE
            DEFB $FE,$82,$F6,$E6,$FA,$BA,$C6,$FE
            DEFB $FE,$F6,$E6,$D6,$B6,$82,$F6,$FE
            DEFB $FE,$82,$BE,$86,$FA,$BA,$C6,$FE
            DEFB $FE,$E6,$DE,$86,$BA,$BA,$C6,$FE
            DEFB $FE,$82,$FA,$F6,$F6,$EE,$EE,$FE
            DEFB $FE,$C6,$BA,$C6,$BA,$BA,$C6,$FE
            DEFB $FE,$C6,$BA,$BA,$C2,$FA,$C6,$FE
            DEFB $FE,$C6,$BA,$BA,$BA,$BA,$C6,$FE

; Сама процедура загрузки по адресу #FC8A
; в основе содержит программу LD-BYTES
; из ПЗУ, которая была подробно описана
; в РЕВЮ-93 №1-2 (стр. 13). Отличия
; незначительны. Все адреса даны
; для новой процедуры.

LD_BYTES:   INC D
            EX AF,AF'
            DEC D
            DI

; Далее, для того, чтобы при
; загрузке хэдера не включался
; счётчик, введены строки:

            EXX
            LD C,$00
            EXX

; Далее опять аналогично ПЗУ:

            LD A,$0A
            OUT ($FE),A
            IN A,($FE)
            RRA
            AND $20
            OR $00
            LD C,A
            CP A
LD_BREAK:   RET NZ
LD_START:   CALL LD_EDGE_1
            JR NC,LD_BREAK
            LD HL,$0415
LD_WAIT:    DJNZ LD_WAIT
            DEC HL
            LD A,H
            OR L
            JR NZ,LD_WAIT
            CALL LD_EDGE_2
            JR NC,LD_BREAK
LD_LEADER:  LD B,$9C
            CALL LD_EDGE_2
            JR NC,LD_BREAK
            LD A,$C6
            CP B
            JR NC,LD_START
            INC H
            JR NZ,LD_LEADER
LD_SYNC:    LD B,$C9
            CALL LD_EDGE_1
            JR NC,LD_BREAK
            LD A,B
            CP $D4
            JR NC,LD_SYNC
            CALL LD_EDGE_1
            RET NC

; Опять, для того, чтобы при
; загрузке хэдера не включался
; счётчик, поставлен выключатель:

            EXX
            LD A,(ENABLED)
            LD C,A
            LD ($FC1F),A
            EXX

; Далее — аналогично ПЗУ:

            LD H,$00
            LD B,$B0
            JR LD_MARKER
LD_LOOP:    EX AF,AF'
            JR NZ,LD_FLAG
            JR NC,LD_VERIFY
            LD (IX+$00),L
            JR LD_NEXT
LD_FLAG:    RL C
            XOR L
            RET NZ
            LD A,C
            RRA
            LD C,A
            INC DE
            JR LD_DEC
LD_VERIFY:  LD A,(IX+$00)
            XOR L
            RET NZ
LD_NEXT:    INC IX
LD_DEC:     DEC DE
            EX AF,AF'
            LD B,$B2
LD_MARKER:  LD L,$01
LD_8_BITS:  CALL LD_EDGE_2
            RET NC
            LD A,$CB
            CP B
            RL L
            LD B,$B0
            JP NC,LD_8_BITS
            LD A,H
            XOR L
            LD H,A
            LD A,D
            OR E
            JR NZ,LD_LOOP
            LD A,H
            CP $01
            RET

; Программы LD_EDGE_2 и LD_ED_GE_1
; изменены следующим образом:

LD_EDGE_2:  CALL LD_EDGE_1
            RET NC
LD_EDGE_1:  JP PICTO
LD_SAMPLE:  INC B
            RET Z
            LD A,$7F
            IN A,($FE)
            RRA
            RET NC
            XOR C
            AND $20
            JR Z,LD_SAMPLE

; Описание работы LD_SAMPLE также можно
; найти в указанном ZX_РЕВЮ. Отличия:

            LD A,C
            CPL
            LD C,A
            LD ($5AFE),A
            LD ($5AFF),A

; — если в отведённое время фронт импульса
; найден, инвертируются все биты на
; противоположные и выдаётся значение
; аккумулятора в две последние ячейки
; атрибутов. Это приводит к тому, что при
; загрузке в двух последних знакоместах
; можно наблюдать полосы, аналогичные
; бордюрным (сам бордюрпри загрузке
; остается чёрным). Далее:

            SCF
            RET
PICTO:      EXX
            LD A,C
            OR A
            JR Z,LD_DELAY

; — если в С ноль, то счётчик не включать.
; Иначе — проверка положения счётчика:

            LD HL,$FC1F
            DEC (HL)
            LD A,(HL)
            JR Z,SHET

; Далее происходит включение атрибутов
; счётчика, а в HL — адрес счётчика в
; таблице:

            CP $05
            JR NC,ATT_R
            LD HL,$FC1B

; Теперь переход на адреса в дисплейном
; файле:

            INC (HL)
            INC L
            INC L
            DEC (HL)
            LD HL,($FC1B)

; Дальнейшая часть вычисляет адрес
; печатаемой цифры:

            LD A,(HL)
            ADD A,$32
            LD E,A
            LD D,$FC

; Следующий фрагмент рисует шаблон,
; лежащий в таблице по адресам
; #FC32 — #FC89:

            LD HL,($FC1D)
            LD A,(DE)
            LD (HL),A
            INC E
            INC H
            LD A,(DE)
            LD (HL),A
            INC E
            INC H
            LD A,(DE)
            LD (HL),A
            INC E
            INC H
            LD A,(DE)
            LD (HL),A
            INC E
            INC H
            LD A,(DE)
            LD (HL),A
            INC E
            INC H
            LD A,(DE)
            LD (HL),A
            INC E
            INC H
            LD A,(DE)
            LD (HL),A
            INC E
            INC H
            LD A,(DE)
            LD (HL),A
            EXX
            JP LD_SAMPLE

; Далее — фрагмент, осуществляющий
; задержку в 358 тактов процессора:

LD_DELAY:   LD B,$17
WAIT_1:     DJNZ WAIT_1
            LD A,$00
            NEG
            AND A
            EXX
            JP LD_SAMPLE

; Затем — установка атрибутов в
; знакоместах счётчика:

ATT_R:      LD A,$47
            LD ($5AFA),A
            LD ($5AFB),A
            LD ($5AFC),A
            LD ($5AFD),A
            INC HL
            INC HL
            LD B,$0D
            JP WAIT_1

; Далее следует процедура SHET:

SHET:       LD B,$4F
            LD DE,($FC16)
            LD HL,($FC18)
            DEC E
            JP P,DES
            LD E,B
            DEC D
            LD B,$05
WAIT_2:     DJNZ WAIT_2
            LD A,(HL)
            JP END_
DES:        LD A,D
            AND $07
            JP Z,SOT_1
            DEC D
            JP P,SOT_2
            LD D,B
            DEC L
            LD A,($8000)
            LD A,($8000)
            LD A,($8000)
            JP END_
SOT_1:      LD A,(HL)
            LD A,(HL)
SOT_2:      LD A,L
            AND $07
            JP Z,HANDR_1
            DEC L
            JP P,HANDR_2
            LD L,B
            DEC H
            NEG
            JP END_
HANDR_1:    LD A,(HL)
            LD A,(HL)
HANDR_2:    LD A,H
            AND $07
            JR Z,END_
            DEC H
END_:       LD ($FC16),DE
            LD ($FC18),HL
            LD HL,$FC15
            LD ($FC1B),HL
            LD HL,$50FE
            LD ($FC1D),HL
            LD A,$40
            LD ($FC1F),A
            NEG
            NEG
            NEG
            AND A
            EXX
            JP LD_SAMPLE

; В приведённой процедуре SHET настолько
; точно просчитаны такты выполнения, что
; она работает не хуже процедуры ПЗУ.
; Если просчи тать все ветви выхода
; программы, то будет 358 тактов. Расчёт
; значений счётчика производится
; следующим образом. Длина программы
; в HL берётся из считанного в таблицу
; хэдера, затем это значение делится
; на 32:

            LD HL,($FC2C)
            LD B,$05
WAIT_3:     SRL H
            RR L
            DJNZ WAIT_3

; Регистр DE также загружается
; из таблицы, а в ВС — заносится
; число, соответствующее десятичному
; 1000:
            LD DE,$FC19
LOOP_2:     LD A,$FF
            LD BC,$03E8

; Повтором получаем в А 0, 1, 2 и т.д.:
LOOP_1:     INC A
            OR A
            SBC HL,BC
            JR NC,LOOP_1

; После сложения и умножения на 8,
; кладём это значение в таблицу:

            ADD HL,BC
            ADD A,A
            ADD A,A
            ADD A,A
            LD (DE),A

; Умножаем HL на 10:

            LD C,L
            LD B,H
            ADD HL,HL
            ADD HL,HL
            ADD HL,BC
            ADD HL,HL

; Переход к следующей ячейке и
; повтор, если не конец:

            DEC DE
            LD A,E
            CP $15
            JR NZ,LOOP_2
            RET

; Чтобы сменить цифру в счётчике,
; обозначающую 1 байт, надо сделать
; 32 вызова процедуры расчёта значения
; счетчика. С началом загрузки программой
; блока кодов включаются атрибуты
; в правом нижнем углу, затем с каждым
; вызовом процедуры LD_EDGE происходит
; смена положения счётчика. Так происходит
; до тех пор, пока блок кодов не
; загрузится и в счётчике не будет "0000".

LD_HEADER:  XOR A
            LD (ENABLED),A
            LD IX,$FC21
            LD DE,$0011
            XOR A
            SCF
            CALL LD_BYTES
            JR NC,ERR
            CALL $FE0F
            LD A,$01
            LD (ENABLED),A
            LD IX,($FC2E)
            LD DE,($FC2C)
            LD A,$FF
            SCF
            CALL LD_BYTES
            JR NC,ERR
            EI
            RET
ERR:        JP $0806
START:      EXX
            PUSH HL
            EXX
            CALL LD_HEADER
            EXX
            POP HL
            EXX
            RET
