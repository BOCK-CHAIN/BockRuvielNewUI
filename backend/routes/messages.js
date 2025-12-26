import express from 'express';
import { verifyJWT } from '../utils/auth.js';
import supabase from '../utils/auth.js';

const router = express.Router();

/**
 * GET /api/messages
 * Get messages between current user and another user
 * Query params: otherUserId (required), limit, offset
 * Requires authentication
 */
router.get('/', verifyJWT, async (req, res) => {
  try {
    const userId = req.userId;
    const { otherUserId } = req.query;
    const limit = Math.min(parseInt(req.query.limit) || 20, 50);
    const offset = parseInt(req.query.offset) || 0;

    // Validate otherUserId
    if (!otherUserId) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'otherUserId is required'
      });
    }

    // Validate UUID format
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(otherUserId)) {
      return res.status(400).json({
        error: 'Invalid user ID',
        message: 'otherUserId must be a valid UUID'
      });
    }

    // Check if other user exists
    const { data: otherUser, error: userError } = await supabase
      .from('profiles')
      .select('id, username, profile_image_url')
      .eq('id', otherUserId)
      .single();

    if (userError || !otherUser) {
      return res.status(404).json({
        error: 'User not found',
        message: 'The other user does not exist'
      });
    }

    // Fetch messages between the two users
    const { data: messages, error } = await supabase
      .from('messages')
      .select(`
        *,
        sender_profile:sender_id!messages_sender_id_fkey(username, profile_image_url),
        receiver_profile:receiver_id!messages_receiver_id_fkey(username, profile_image_url)
      `)
      .or(`and(sender_id.eq.${userId},receiver_id.eq.${otherUserId}),and(sender_id.eq.${otherUserId},receiver_id.eq.${userId})`)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) {
      console.error('❌ Messages fetch error:', error);
      return res.status(500).json({
        error: 'Database error',
        message: 'Failed to fetch messages'
      });
    }

    // Get total messages count
    const { count: totalCount, error: countError } = await supabase
      .from('messages')
      .select('*', { count: 'exact', head: true })
      .or(`and(sender_id.eq.${userId},receiver_id.eq.${otherUserId}),and(sender_id.eq.${otherUserId},receiver_id.eq.${userId})`);

    if (countError) {
      console.error('❌ Messages count error:', countError);
    }

    // Mark messages as read (where current user is receiver)
    const { error: readError } = await supabase
      .from('messages')
      .update({ read_at: new Date().toISOString() })
      .eq('sender_id', otherUserId)
      .eq('receiver_id', userId)
      .is('read_at', null);

    if (readError) {
      console.error('❌ Mark messages as read error:', readError);
    }

    res.json({
      messages: messages.reverse().map(message => ({
        id: message.id,
        sender_id: message.sender_id,
        receiver_id: message.receiver_id,
        message: message.message,
        message_type: message.message_type || 'text',
        created_at: message.created_at,
        read_at: message.read_at,
        sender_username: message.sender_profile?.username || 'Unknown',
        sender_profile_image_url: message.sender_profile?.profile_image_url,
        receiver_username: message.receiver_profile?.username || 'Unknown',
        receiver_profile_image_url: message.receiver_profile?.profile_image_url
      })),
      other_user: otherUser,
      pagination: {
        limit,
        offset,
        total_count: totalCount || 0,
        has_more: messages.length === limit
      }
    });
  } catch (error) {
    console.error('❌ Messages endpoint error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to fetch messages'
    });
  }
});

/**
 * POST /api/messages
 * Send a message to another user
 * Requires authentication
 */
router.post('/', verifyJWT, async (req, res) => {
  try {
    const userId = req.userId;
    const { receiver_id, message, message_type = 'text' } = req.body;

    // Validate inputs
    if (!receiver_id || !message) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'receiver_id and message are required'
      });
    }

    if (typeof message !== 'string' || message.trim().length === 0) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'Message text is required and cannot be empty'
      });
    }

    if (message.length > 2000) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'Message cannot exceed 2000 characters'
      });
    }

    // Validate message type
    if (!['text', 'image', 'video'].includes(message_type)) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'message_type must be text, image, or video'
      });
    }

    // Validate UUID format for receiver
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(receiver_id)) {
      return res.status(400).json({
        error: 'Invalid receiver ID',
        message: 'receiver_id must be a valid UUID'
      });
    }

    // Cannot send message to yourself
    if (receiver_id === userId) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'Cannot send message to yourself'
      });
    }

    // Check if receiver exists
    const { data: receiver, error: receiverError } = await supabase
      .from('profiles')
      .select('id')
      .eq('id', receiver_id)
      .single();

    if (receiverError || !receiver) {
      return res.status(404).json({
        error: 'Receiver not found',
        message: 'The receiver does not exist'
      });
    }

    // Generate message ID
    const messageId = Date.now().toString() + '_' + Math.random().toString(36).substring(2, 11);

    // Create message
    const { data: newMessage, error } = await supabase
      .from('messages')
      .insert({
        id: messageId,
        sender_id: userId,
        receiver_id: receiver_id,
        message: message.trim(),
        message_type: message_type,
        created_at: new Date().toISOString()
      })
      .select(`
        *,
        sender_profile:sender_id!messages_sender_id_fkey(username, profile_image_url),
        receiver_profile:receiver_id!messages_receiver_id_fkey(username, profile_image_url)
      `)
      .single();

    if (error) {
      console.error('❌ Message creation error:', error);
      return res.status(500).json({
        error: 'Database error',
        message: 'Failed to send message'
      });
    }

    res.status(201).json({
      message: 'Message sent successfully',
      data: {
        id: newMessage.id,
        sender_id: newMessage.sender_id,
        receiver_id: newMessage.receiver_id,
        message: newMessage.message,
        message_type: newMessage.message_type,
        created_at: newMessage.created_at,
        read_at: newMessage.read_at,
        sender_username: newMessage.sender_profile?.username || 'Unknown',
        sender_profile_image_url: newMessage.sender_profile?.profile_image_url,
        receiver_username: newMessage.receiver_profile?.username || 'Unknown',
        receiver_profile_image_url: newMessage.receiver_profile?.profile_image_url
      }
    });
  } catch (error) {
    console.error('❌ Message creation endpoint error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to send message'
    });
  }
});

/**
 * GET /api/messages/conversations
 * Get list of conversations for current user
 * Requires authentication
 */
router.get('/conversations', verifyJWT, async (req, res) => {
  try {
    const userId = req.userId;
    const limit = Math.min(parseInt(req.query.limit) || 20, 50);
    const offset = parseInt(req.query.offset) || 0;

    // Get latest message with each user
    const { data: conversations, error } = await supabase
      .from('messages')
      .select(`
        *,
        sender_profile:sender_id!messages_sender_id_fkey(username, profile_image_url),
        receiver_profile:receiver_id!messages_receiver_id_fkey(username, profile_image_url)
      `)
      .or(`sender_id.eq.${userId},receiver_id.eq.${userId}`)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('❌ Conversations fetch error:', error);
      return res.status(500).json({
        error: 'Database error',
        message: 'Failed to fetch conversations'
      });
    }

    // Group by other user and get latest message
    const conversationMap = new Map();
    
    for (const message of conversations) {
      const otherUserId = message.sender_id === userId ? message.receiver_id : message.sender_id;
      
      if (!conversationMap.has(otherUserId)) {
        conversationMap.set(otherUserId, message);
      }
    }

    // Convert to array and paginate
    const conversationList = Array.from(conversationMap.values())
      .slice(offset, offset + limit);

    // Get unread counts for each conversation
    const unreadCounts = {};
    for (const [otherUserId] of conversationMap) {
      const { count, error } = await supabase
        .from('messages')
        .select('*', { count: 'exact', head: true })
        .eq('sender_id', otherUserId)
        .eq('receiver_id', userId)
        .is('read_at', null);

      if (!error) {
        unreadCounts[otherUserId] = count || 0;
      }
    }

    res.json({
      conversations: conversationList.map(message => {
        const otherUserId = message.sender_id === userId ? message.receiver_id : message.sender_id;
        const otherUser = message.sender_id === userId ? message.receiver_profile : message.sender_profile;
        
        return {
          other_user_id: otherUserId,
          other_username: otherUser?.username || 'Unknown',
          other_profile_image_url: otherUser?.profile_image_url,
          last_message: {
            id: message.id,
            message: message.message,
            message_type: message.message_type,
            created_at: message.created_at,
            sender_id: message.sender_id
          },
          unread_count: unreadCounts[otherUserId] || 0
        };
      }),
      pagination: {
        limit,
        offset,
        has_more: conversationList.length === limit
      }
    });
  } catch (error) {
    console.error('❌ Conversations endpoint error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to fetch conversations'
    });
  }
});

/**
 * PUT /api/messages/:id/read
 * Mark a message as read
 * Requires authentication
 */
router.put('/:id/read', verifyJWT, async (req, res) => {
  try {
    const userId = req.userId;
    const { id: messageId } = req.params;

    // Validate UUID format
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(messageId)) {
      return res.status(400).json({
        error: 'Invalid message ID',
        message: 'Message ID must be a valid UUID'
      });
    }

    // Check if message exists and user is receiver
    const { data: message, error: fetchError } = await supabase
      .from('messages')
      .select('receiver_id, read_at')
      .eq('id', messageId)
      .single();

    if (fetchError || !message) {
      return res.status(404).json({
        error: 'Message not found',
        message: 'Message does not exist'
      });
    }

    if (message.receiver_id !== userId) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'You can only mark messages as read if you are the receiver'
      });
    }

    if (message.read_at) {
      return res.status(200).json({
        message: 'Message already marked as read'
      });
    }

    // Mark as read
    const { error } = await supabase
      .from('messages')
      .update({ read_at: new Date().toISOString() })
      .eq('id', messageId);

    if (error) {
      console.error('❌ Mark message as read error:', error);
      return res.status(500).json({
        error: 'Database error',
        message: 'Failed to mark message as read'
      });
    }

    res.json({
      message: 'Message marked as read successfully'
    });
  } catch (error) {
    console.error('❌ Mark message as read endpoint error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to mark message as read'
    });
  }
});

export default router;