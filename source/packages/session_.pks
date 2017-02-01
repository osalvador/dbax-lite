CREATE OR REPLACE PACKAGE session_
AS
   /**
   * Start new the session. Note, do not start a new session if a previous one already exists.
   *
   * @param     p_username          If it exists, the user id that starts the session
   * @param     p_session_expires   the session expiration date
   */
   PROCEDURE init (p_username IN VARCHAR2 DEFAULT NULL , p_session_expires IN DATE DEFAULT NULL );

   /**
   * Determine if the session has been started.
   */
   FUNCTION is_started
      RETURN BOOLEAN;

   /**
   * Save the session data.
   */
   PROCEDURE save;

   /**
   * Retrieve a session variable from the request
   *
   * @param  p_key     the session key
   *
   * @return the value if exists
   */
   FUNCTION get (p_key IN VARCHAR2)
      RETURN VARCHAR2;

   /**
   * Get the current session ID.
   *
   * @return    the user user sessid
   */
   FUNCTION getid
      RETURN VARCHAR2;

   /**
   * Set a key/value pair in the session.
   *
   * @param  p_key     the key or variable name
   * @param  p_value   the value
   */
   PROCEDURE set (p_key IN VARCHAR2, p_value IN VARCHAR2);

   /**
   * Delete an item from the session
   *
   * @param  p_key     the key or variable name
   */
   PROCEDURE delete (p_key IN VARCHAR2);

   /**
   * Remove all of the items from the session.
   */
   PROCEDURE flush;

   /**
   * End current session, cookie and delete all session variables
   */
   PROCEDURE finish;
END session_;
/