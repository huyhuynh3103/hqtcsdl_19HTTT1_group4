--T1 nhan vien 1 cap nhat thoi gian hieu luc hop dong cua doi tac
--T2 nhan vien 2 cap nhat thoi gian hieu luc hop dong cua doi tac
-- T2
go
use OnlineOrderingSystem

GO
CREATE PROCEDURE sp_lostupdate_tc1_T2_error @masothue varchar(20), @tg_hlhd date, @pthh float
AS
BEGIN TRAN 
	IF IS_ROLEMEMBER('nhan_vien') = 0 AND IS_ROLEMEMBER('db_owner') = 0
		BEGIN
			ROLLBACK TRAN
		END
	ELSE
		BEGIN
			IF NOT EXISTS(SELECT h.TG_HieuLucHD FROM DOI_TAC d JOIN HOP_DONG h ON (d.MaDT = h.MaDT) WHERE d.MaSoThue = @masothue)
				BEGIN
					ROLLBACK TRAN
					PRINT('TRANSACTION IS ROLLBACKED')
				END 
			ELSE
				BEGIN
					-- Check if the input effective time is valid
					IF(@tg_hlhd < (SELECT h.TG_HieuLucHD FROM DOI_TAC d JOIN HOP_DONG h ON (d.MaDT = h.MaDT) WHERE d.MaSoThue = @masothue))
						BEGIN
							ROLLBACK TRAN
							PRINT('TRANSACTION IS ROLLBACKED')
						END
					ELSE
						BEGIN
							UPDATE HOP_DONG
							SET TG_HieuLucHD = @tg_hlhd, PhanTramHoaHong = @pthh
							where MaDT IN (SELECT MaDT FROM DOI_TAC WHERE MaSoThue = @masothue)

							Waitfor Delay '00:00:10'
							COMMIT TRAN;
						END
					END
				END
