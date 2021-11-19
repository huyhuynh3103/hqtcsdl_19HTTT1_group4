--Cycle deadlock
--Test case 2
-- T1 - Tai Xe
GO
CREATE PROCEDURE sp_deadlock_tc2_T1 @madh varchar(20), @matx varchar(20)
AS
BEGIN TRAN 
	IF IS_ROLEMEMBER('tai_xe') = 0 AND IS_ROLEMEMBER('dbowner') = 0
		BEGIN
			ROLLBACK TRAN
		END
	ELSE
		BEGIN
			IF NOT EXISTS(SELECT MaDH FROM DON_HANG WHERE MaDH = @madh) 
			OR EXISTS (SELECT MaDH FROM GIAO_HANG WHERE MaDH = @madh) 
			OR NOT EXISTS (SELECT MaTX FROM TAI_XE WHERE MaTX = @matx)
				BEGIN
					ROLLBACK TRAN
				END
			SET TRAN ISOLATION LEVEL SERIALIZABLE
			INSERT INTO GIAO_HANG WITH (HOLDLOCK)
			VALUES(@matx,@madh,NULL)
			Waitfor Delay '0:0:10'
			UPDATE DON_HANG WITH (XLOCK)
			SET TinhTrangDH = 'Tai xe da nhan hang'
			WHERE MaDH = @madh
			COMMIT TRAN
		END

GO 
USE OnlineOrderingSystem
GRANT EXEC ON sp_deadlock_tc2_T1
TO tai_xe

GO 
USE OnlineOrderingSystem
EXEC sp_deadlock_tc2_T1 '004','005'