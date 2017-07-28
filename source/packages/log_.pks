CREATE OR REPLACE PACKAGE log_
AS
   /************************************************************************
   *                            LOGGING
   *                      dbax loggin solution API
   *
   * The logger provides the eight logging levels defined in RFC 5424
   *
   *  Numerical         Severity
   *    Code
   *
   *     0               Emergency: system is unusable
   *     1               Alert: action must be taken immediately
   *     2               Critical: critical conditions
   *     3               Error: error conditions
   *     4               Warning: warning conditions
   *     5               Notice: normal but significant condition
   *     6               Informational: informational messages
   *     7               Debug: debug-level messages
   *
   *************************************************************************/

   k_log_level_emergency CONSTANT       NUMBER := 0;
   k_log_level_alert CONSTANT           NUMBER := 1;
   k_log_level_critical CONSTANT        NUMBER := 2;
   k_log_level_error CONSTANT           NUMBER := 3;
   k_log_level_warning CONSTANT         NUMBER := 4;
   k_log_level_notice CONSTANT          NUMBER := 5;
   k_log_level_info CONSTANT            NUMBER := 6;
   k_log_level_debug CONSTANT           NUMBER := 7;

   k_log_level_emergency_str CONSTANT   VARCHAR2 (10) := 'emergency';
   k_log_level_alert_str CONSTANT       VARCHAR2 (10) := 'alert';
   k_log_level_critical_str CONSTANT    VARCHAR2 (10) := 'critical';
   k_log_level_error_str CONSTANT       VARCHAR2 (10) := 'error';
   k_log_level_warning_str CONSTANT     VARCHAR2 (10) := 'warning';
   k_log_level_notice_str CONSTANT      VARCHAR2 (10) := 'notice';
   k_log_level_info_str CONSTANT        VARCHAR2 (10) := 'info';
   k_log_level_debug_str CONSTANT       VARCHAR2 (10) := 'debug';


   /**
   * Write the in memory log to the log table
   *
   */
   PROCEDURE write;

   /**
   * Write the in memory log to the log table
   *
   * @return  number    the log id of the log table 
   */
   FUNCTION write
      RETURN NUMBER;

   /**
   * Log a emergency message to the logs.
   *
   * @param  p_message    the message to write to the log. 
   */
   PROCEDURE emergency (p_message IN CLOB);

   /**
   * Log a alert message to the logs.
   *
   * @param  p_message    the message to write to the log. 
   */
   PROCEDURE alert (p_message IN CLOB);

   /**
   * Log a critical message to the logs.
   *
   * @param  p_message    the message to write to the log. 
   */
   PROCEDURE critical (p_message IN CLOB);

   /**
   * Log a error message to the logs.
   *
   * @param  p_message    the message to write to the log. 
   */
   PROCEDURE error (p_message IN CLOB);

   /**
   * Log a warning message to the logs.
   *
   * @param  p_message    the message to write to the log. 
   */
   PROCEDURE warning (p_message IN CLOB);

   /**
   * Log a notice message to the logs.
   *
   * @param  p_message    the message to write to the log. 
   */
   PROCEDURE notice (p_message IN CLOB);

   /**
   * Log a info message to the logs.
   *
   * @param  p_message    the message to write to the log. 
   */
   PROCEDURE info (p_message IN CLOB);

   /**
   * Log a debug message to the logs.
   *
   * @param  p_message    the message to write to the log. 
   */
   PROCEDURE debug (p_message IN CLOB);
END log_;
/